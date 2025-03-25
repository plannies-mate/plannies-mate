# frozen_string_literal: true

# Gemfile for roles/app/files sinatra app
# Kept in project root to make it easier with rubymine

source 'https://rubygems.org'

gem 'slim', '~> 5.2' # Template for generating static html pages
gem 'tilt', '~> 2.6' # Assists with using slim outside of rails
gem 'tzinfo', '~> 2.0'

group :app do
  gem 'puma', '~> 6.6'
  gem 'rackup', '~> 2.2'
  gem 'sinatra', '~> 4.1' # Requesting refresh and basic debug info
  gem 'sinatra-contrib', '~> 4.1' # Extras like json rendering
end

group :tasks do
  gem 'activerecord', '~> 8.0'
  gem 'activesupport', '~> 8.0'
  gem 'faraday-retry', '~> 2.2' # Retry for octokit
  gem 'json', '~> 2.10'
  gem 'mechanize', '~> 2.14' #  Web Scraping morph.io
  gem 'nokogiri', '~> 1.18' # to enforce freshness of gem used by mechanize
  gem 'octokit', '~> 9.2' # GitHub API access
  gem 'rake', '~> 13.2' # For tasks
  gem 'sinatra-activerecord', '~> 2.0'
  gem 'sqlite3', '~> 2.6'
end

group :development, :test do
  gem 'annotaterb', '4.7.1' # versions 4.8 through 4.14 have a bug with yml files
  gem 'rack-test', '~> 2.2'
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.74'
  gem 'simplecov', '~> 0.22.0'
  gem 'simplecov-console', '~> 0.9.3'
  gem 'vcr', '~> 6.3'
  gem 'webmock', '~> 3.25'
end
