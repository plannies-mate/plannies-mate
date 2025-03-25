# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'simplecov'
require 'simplecov-console'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
  ]
)
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Fetchers', 'app/fetchers'
  add_group 'Generators', 'app/generators'
  add_group 'Helpers', 'app/helpers'
  add_group 'Library', 'lib'
  add_group 'Matchers', 'app/matchers'
  add_group 'Models', 'app/models'
  add_group 'Tasks', 'tasks'
end

require 'fileutils'
require 'json'
require 'time'
require 'tempfile'
require 'rspec'
require 'vcr'
require 'webmock/rspec'

# Setup ActiveRecord connection for tests
require 'sinatra/activerecord'
require_relative '../config/boot'
require_relative '../app'
require_relative '../tasks'
require_gems_for(:app, :tasks)

# Configure settings
App.configure_sinatra_options(Sinatra::Base)
# We don't setup routes as that is much harder

# Database configuration
database_config = YAML.load_file(File.expand_path('../config/database.yml', __dir__), aliases: true)
ActiveRecord::Base.establish_connection(database_config['test'])

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir = File.expand_path('cassettes', __dir__)
  config.hook_into :webmock
  config.ignore_request { ENV.fetch('DISABLE_VCR', nil) }
  config.ignore_localhost = true
  config.configure_rspec_metadata!

  # Filter out sensitive information if needed
  # config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }

  # Allow localhost requests (useful for testing against local services)
  config.ignore_localhost = true

  # Set default recording mode - one of :once, :new_episodes, :none, :all
  vcr_mode = ENV.fetch('VCR_MODE', nil) =~ /rec/i ? :all : :once
  config.default_cassette_options = {
    record: vcr_mode,
    match_requests_on: %i[method uri body],
  }
end

# Configure RSpec
RSpec.configure do |config|
  config.include AppHelpersAccessor

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  # Make it stop on the first failure. Makes in this case
  # for quicker debugging
  config.fail_fast = !ENV['FAIL_FAST'].blank?

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  # Create VCR cassette directory if it doesn't exist
  config.before(:suite) do
    FileUtils.mkdir_p('spec/fixtures/vcr_cassettes')
  end
end

# Helper function to create cassette names that reflect the spec file and context
def cassette_name(description)
  # Get the calling file's name without path and extension
  file = caller_locations(1, 1)[0].path.split('/').last.gsub('.rb', '')
  
  # Clean up the description
  desc = description.to_s.downcase.gsub(/[^a-z0-9]+/, '_')
  
  "#{file}/#{desc}"
end

# Helper method to create a temporary directory
def create_temp_dir(prefix = 'test')
  path = File.join(Dir.tmpdir, "#{prefix}_#{Time.now.to_i}_#{rand(1000)}")
  FileUtils.mkdir_p(path)
  path
end

# Load all support files
Dir[File.expand_path('./support/**/*.rb', __dir__)].each { |f| require f }

# Load all files so they appear in coverage
Dir.glob(File.expand_path('../app/**/*.rb', __dir__)).each { |r| require r }
Dir.glob(File.expand_path('../lib/**/*.rb', __dir__)).each { |r| require r }

# Fixture Helpers
module Fixture
  extend AppHelpersAccessor

  # Define the load order based on dependencies
  FIXTURES = [
    ['coverage_histories', CoverageHistory],
    ['github_users', GithubUser],
    ['issue_labels', IssueLabel],
    ['scrapers', Scraper],
    # Tables with references
    ['pull_requests', PullRequest], # references scraper
    ['authorities', Authority], # depends on scraper
    ['issues', Issue], # Depends on authority and github_user
    # Join tables with fixtures
    ['authorities_pull_requests', nil],
    ['issue_labels_issues', nil], # HABTM
    ['github_users_issues', nil], # HABTM
  ].freeze
  ASSOCIATIONS = %w[assignee authority github_user issue_label issue pull_request scraper user].freeze

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

            attributes["#{assoc}_id"] = Fixture.id_for(assoc_key)
            puts "  with #{assoc}: #{assoc_key} => #{assoc}_id #{attributes["#{assoc}_id"]}" if app_helpers.debug?
          end
          if model
            attributes['id'] ||= Fixture.id_for(key)
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
          puts "ERROR: Creating fixture #{fixture_name}:#{key}: #{e}"
          raise e
        end
        puts "Loaded #{model ? model.count : fixtures.size} #{fixture_name} records" if app_helpers.debug?
      end
    end
  end
end

# Ensure test database is prepared before tests
begin
  # Only load and run the task if the database needs updating
  Rake.application.load_rakefile
  Rake::Task['db:test:prepare'].invoke
rescue StandardError => e
  puts "Warning: Failed to prepare test database: #{e.message}"
end

RSpec.configure do |config|
  config.extend VcrHelper
  config.include TimeHelpers  # Include our time helpers

  config.before(:suite) do
    Fixture.clear_database
    Fixture.load_fixtures
  end

  # Use transactions for each test
  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      # puts "ROLLBACK ----------------------"
      raise ActiveRecord::Rollback
    end
  end
end
