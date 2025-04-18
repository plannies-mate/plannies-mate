# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir = File.expand_path('../cassettes', __dir__)
  config.hook_into :webmock
  config.ignore_request { ENV.fetch('DISABLE_VCR', nil) }
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  # Allow localhost requests (useful for testing against local services)
  config.ignore_localhost = true

  # Filter sensitive information
  config.filter_sensitive_data('<GITHUB_TOKEN>') do |interaction|
    Regexp.last_match(1) if interaction.request.headers['Authorization']&.first =~ /^token\s+(.+)/
  end
  config.filter_sensitive_data('<MORPH_API_KEY>') do |interaction|
    CGI.unescape(Regexp.last_match(1)) if interaction.request.uri.match(/key=([^&]+)/)
  end

  # Set default recording mode - one of :once, :new_episodes, :none, :all
  vcr_mode = ENV.fetch('VCR_MODE', nil) =~ /rec/i ? :all : :once
  config.default_cassette_options = {
    record: vcr_mode,
    match_requests_on: %i[method uri body],
  }
end

module VcrHelper
  # Helper function to create cassette names that reflect the spec file and context
  def cassette_name(description)
    # Get the calling file's name without path and extension
    file = caller_locations(1, 1)[0].path.split('/').last.gsub('.rb', '')

    # Clean up the description
    desc = description.to_s.downcase.gsub(/[^a-z0-9]+/, '_')

    "#{file}/#{desc}"
  end
end
