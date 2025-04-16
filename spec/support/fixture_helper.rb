# frozen_string_literal: true

# FixtureHelper Helpers
module FixtureHelper
  extend AppHelpersAccessor

  # Define the load order based on dependencies
  FIXTURES = [
    ['http_cache_entries', HttpCacheEntry],
    ['coverage_histories', CoverageHistory],
    ['users', User],
    ['issue_labels', IssueLabel],
    ['scrapers', Scraper],
    # Tables with references
    ['authorities', Authority], # Depends on scrapers,
    ['issues', Issue], # Depends on authority, scrapers and user
    ['pull_requests', PullRequest], # references scraper
    ['test_results', TestResult],
    ['authority_test_results', AuthorityTestResult],
    # Join tables with fixtures
    ['issue_labels_issues', nil], # HABTM
    ['issue_assignees', nil], # HABTM
    ['pull_request_assignees', nil], # HABTM
  ].freeze

  ASSOCIATIONS = %w[authority coverage_history user issue_label issue pull_request scraper test_result].freeze

  def self.id_for(value)
    (value.to_s.hash.abs % 0x7FFFFFFE) + 1
  end

  def self.find(model, key)
    model.find_by(id: id_for(key))
  end

  def self.clear_database
    ActiveRecord::Base.transaction do
      connection = ActiveRecord::Base.connection
      FIXTURES.reverse.each do |fixture_name, model|
        if model
          puts "Deleting all #{model.name} records (#{fixture_name} table) ..." if app_helpers.debug?
          model.delete_all
        else
          table_name = connection.quote_table_name(fixture_name)
          puts "Deleting all #{fixture_name} HABTM records ..." if app_helpers.debug?
          ActiveRecord::Base.connection.execute "DELETE FROM #{table_name}"
        end
      end
    end
  end

  def self.load_fixtures
    ActiveRecord::Base.transaction do
      connection = ActiveRecord::Base.connection
      FIXTURES.each do |fixture_name, model|
        fixture_file = File.join('spec/fixtures', "#{fixture_name}.yml")
        fixtures = YAML.unsafe_load_file(fixture_file)
        fixtures.each do |key, attributes|
          ASSOCIATIONS.each do |assoc|
            next unless (assoc_key = attributes.delete(assoc))

            attributes["#{assoc}_id"] = FixtureHelper.id_for(assoc_key)
            puts "  with #{assoc}: #{assoc_key} => #{assoc}_id #{attributes["#{assoc}_id"]}" if app_helpers.debug?
          end
          if model
            attributes['id'] ||= FixtureHelper.id_for(key)
            puts "Creating fixture #{fixture_name}:#{key}, id: #{attributes['id']}" if app_helpers.debug?
            model.create!(attributes)
          else
            puts "Creating fixture #{fixture_name}:#{key}, #{attributes.inspect}" if app_helpers.debug?
            columns = attributes.keys.map { |column| connection.quote_column_name(column) }
            values = attributes.values.map { |value| connection.quote(value) }
            table_name = connection.quote_table_name(fixture_name)
            sql = "INSERT INTO #{table_name} (#{columns.join(', ')}) VALUES (#{values.join(', ')})"
            connection.execute(sql)
          end
        rescue StandardError, ActiveRecord::RecordInvalid => e
          puts "ERROR: Creating fixture #{fixture_name}:#{key}: #{e}#{defined?(attributes) ? ", #{attributes.inspect}" : ''}"
          raise e
        end
        puts "Loaded #{model ? model.count : fixtures.size} #{fixture_name} records" if app_helpers.debug?
      end
    end
  end
end
