# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require_relative '../config/boot'
require_gems_for(:app, :tasks, 'Specs')

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
require_relative '../app'
require_relative '../tasks'

# Configure settings
App.configure_sinatra_options(Sinatra::Base)
# NOTE: We don't setup routes as that is much harder

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

# Load all support files
Dir[File.expand_path('./support/**/*.rb', __dir__)].each { |f| require f }

# Load all files so they appear in coverage
Dir.glob(File.expand_path('../app/**/*.rb', __dir__)).each { |r| require r }
Dir.glob(File.expand_path('../lib/**/*.rb', __dir__)).each { |r| require r }

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
  config.include TimeHelper # Include our time helpers
  config.include AppHelpersAccessor

  config.before(:suite) do
    FixtureHelper.clear_database
    FixtureHelper.load_fixtures
  end

  # Use transactions for each test
  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      # puts "ROLLBACK ----------------------"
      raise ActiveRecord::Rollback
    end
  end

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
