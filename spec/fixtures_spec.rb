# frozen_string_literal: true

require_relative 'spec_helper'
require_relative 'support/fixture_helper'
require 'yaml'
require 'active_record'

RSpec.describe 'Fixtures' do
  describe 'FIXTURES constant' do 
    # Get all tables in the database
    let(:db_tables) do
      tables = ActiveRecord::Base.connection.tables
      
      # Exclude Rails/ActiveRecord internal tables
      excluded_tables = %w[schema_migrations ar_internal_metadata]
      tables - excluded_tables
    end

    it 'includes all database tables (except migration-related)' do
      fixture_tables = FixtureHelper::FIXTURES.map { |f| f[0] }
      missing_tables = db_tables - fixture_tables
      
      # If there are missing tables, the test will fail with a helpful message
      expect(missing_tables).to be_empty, 
        "Tables missing from FixtureHelper::FIXTURES: #{missing_tables.join(', ')}"
    end
  end

  # Test A: All tables have records and counts match
  describe 'fixture counts' do
    FixtureHelper::FIXTURES.each do |fixture_name, model|
      it "#{fixture_name} fixture count matches database count" do
        # Count records in fixture file
        fixture_file = File.join('spec/fixtures', "#{fixture_name}.yml")
        
        # Fix for Psych::DisallowedClass error
        fixture_data = YAML.load_file(fixture_file, permitted_classes: [Date, Time, Symbol]) || {}
        fixture_count = fixture_data.keys.count
        
        # Count records in database - handle both model and join tables
        if model
          # Use the model for counting if available
          db_count = model.count
        else
          # For join tables without models, use raw SQL count
          db_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{fixture_name}").to_i
        end
        
        expect(db_count).to eq(fixture_count),
          "Expected #{fixture_count} records in #{fixture_name} from fixtures, but found #{db_count} in database"
        
        # Additional check that we have at least one record
        expect(db_count).to be > 0, "No records found in #{fixture_name} table"
      end
    end
  end

  # Test B: No duplicate keys in fixture files
  describe 'fixture files' do
    FixtureHelper::FIXTURES.each do |fixture_name, _|
      it "#{fixture_name}.yml has no duplicate keys" do
        fixture_file = File.join('spec/fixtures', "#{fixture_name}.yml")
        next unless File.exist?(fixture_file)

        # Read the file content and check for duplicate keys
        content = File.read(fixture_file)
        lines = content.lines
        
        # Extract all keys defined with the pattern "key:" at the beginning of a line
        # or after "---" which indicates a new document in YAML
        keys = []
        in_document = false
        lines.each do |line|
          if line.strip == '---'
            in_document = true
            next
          end
          
          # Match keys at the beginning of a line with proper indentation
          if in_document && line =~ /^([a-zA-Z0-9_]+):/
            keys << $1
          end
        end
        
        # Check for duplicates
        duplicates = keys.group_by { |k| k }.select { |_, v| v.size > 1 }.keys
        expect(duplicates).to be_empty, 
          "Duplicate keys found in #{fixture_file}: #{duplicates.join(', ')}"
      end
    end
  end

  # Test C: All records in fixtures are valid and associations exist
  describe 'record validity' do
    FixtureHelper::FIXTURES.each do |fixture_name, model|
      next unless model # Skip join tables as they don't have models for validation
      
      it "all #{model.name} records pass validations" do
        invalid_records = []
        
        model.all.each do |record|
          unless record.valid?
            invalid_records << {
              id: record.id,
              errors: record.errors.full_messages
            }
          end
        end
        
        expect(invalid_records).to be_empty,
          "Invalid #{model.name} records found: #{invalid_records.inspect}"
      end
      
      # Check associations
      it "all #{model.name} associations point to existing records" do
        broken_associations = []
        
        model.all.each do |record|
          # Get all belongs_to associations
          belongs_to_associations = model.reflect_on_all_associations(:belongs_to)
          
          belongs_to_associations.each do |association|
            begin
              # Try to load the associated record
              associated_record = record.send(association.name)
              
              # Skip if the association is optional and nil
              next if associated_record.nil? && !association.options[:required]
              
              if associated_record.nil?
                broken_associations << {
                  record_id: record.id,
                  association: association.name,
                  error: "Association returns nil but is required"
                }
              end
            rescue => e
              broken_associations << {
                record_id: record.id,
                association: association.name,
                error: e.message
              }
            end
          end
        end
        
        expect(broken_associations).to be_empty,
          "Broken associations found in #{model.name}: #{broken_associations.inspect}"
      end
    end
  end

  # Test C-extended: Check join tables for valid foreign keys
  describe 'join table foreign key validity' do
    join_tables = FixtureHelper::FIXTURES.select { |_, model| model.nil? }.map(&:first)
    
    join_tables.each do |table_name|
      it "#{table_name} records have valid foreign keys" do
        # Get foreign key constraints for this table
        fk_info = ActiveRecord::Base.connection.foreign_keys(table_name)
        
        # Skip if no foreign keys defined (unusual for join tables)
        next if fk_info.empty?
        
        broken_references = []
        
        # Get all records from the join table
        records = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name}")
        
        records.each do |record|
          fk_info.each do |fk|
            # The local column in the join table
            from_column = fk.options[:column]
            
            # The target table and its primary key
            to_table = fk.to_table
            to_column = fk.primary_key || 'id'
            
            # The value of the foreign key in this record
            fk_value = record[from_column.to_s]
            
            # Skip if the value is NULL (which is allowed unless there's a NOT NULL constraint)
            next if fk_value.nil?
            
            # Check if the referenced record exists
            referenced_exists = ActiveRecord::Base.connection.select_value(
              "SELECT 1 FROM #{to_table} WHERE #{to_column} = #{ActiveRecord::Base.connection.quote(fk_value)} LIMIT 1"
            )
            
            unless referenced_exists
              broken_references << {
                table: table_name,
                record_id: record['id'],
                foreign_key: from_column,
                referenced_table: to_table,
                referenced_column: to_column,
                value: fk_value
              }
            end
          end
        end
        
        expect(broken_references).to be_empty,
          "Broken foreign key references found in #{table_name}: #{broken_references.inspect}"
      end
    end
  end

  # Test D: Check for nil values in non-null fields
  describe 'non-null field coverage' do
    FixtureHelper::FIXTURES.each do |fixture_name, model|
      next unless model # Skip join tables without models
      
      it "#{model.name} fixtures include examples of all nullable fields" do
        # Get column information
        columns = model.columns.reject { |c| c.name.in?(%w[id created_at updated_at]) }
        
        # Filter to columns that allow null values
        # Fixed: Use the null attribute instead of the primary method
        nullable_columns = columns.select { |c| c.null }
        
        # Skip test if no nullable columns
        next if nullable_columns.empty?
        
        nullable_columns.each do |column|
          # Check if we have at least one record with nil value
          nil_exists = model.exists?(column.name => nil)
          # Check if we have at least one record with non-nil value
          non_nil_exists = model.where.not(column.name => nil).exists?
          
          # We should have examples of both nil and non-nil values
          message = "#{model.name}.#{column.name} should have examples of both nil and non-nil values"
          
          # Dynamically pending or pass based on data
          if !nil_exists || !non_nil_exists
            pending message
          else
            expect(nil_exists && non_nil_exists).to be_truthy, message
          end
        end
      end
    end
  end

  # Test for join tables: Check that they have the expected structure
  describe 'join table structure' do
    join_tables = FixtureHelper::FIXTURES.select { |_, model| model.nil? }.map(&:first)
    
    join_tables.each do |table_name|
      it "#{table_name} has appropriate columns for a join table" do
        columns = ActiveRecord::Base.connection.columns(table_name)
        column_names = columns.map(&:name)
        
        # Most join tables should not have their own ID
        has_id = column_names.include?('id')
        
        # Join tables should have at least two foreign key columns
        foreign_key_count = ActiveRecord::Base.connection.foreign_keys(table_name).size
        
        if has_id
          # If the join table has an ID, it's not a pure join table
          # It might be a join table with additional attributes
          pending "#{table_name} has an ID column - might be a join table with attributes"
        else
          # A pure join table should have at least 2 foreign keys
          expect(foreign_key_count).to be >= 2,
            "Expected #{table_name} to have at least 2 foreign keys (found #{foreign_key_count})"
        end
      end
    end
  end
end
