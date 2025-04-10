# frozen_string_literal: true

require_relative '../importers/authorities_importer'
require_relative '../importers/issues_importer'
require_relative '../importers/pull_requests_importer'

namespace :import do
  desc 'Import all information from remote sites'
  task all: %i[singleton authorities issues pull_requests] do
    puts 'Finished'
  end

  desc 'Import planning authority list from PlanningAlerts'
  task authorities: :singleton do
    authorities_importer = AuthoritiesImporter.new
    authorities_importer.import
  end

  desc 'Import Open Issues'
  task issues: :singleton do
    fetcher = IssuesImporter.new
    fetcher.import
  end

  desc 'Import pull requests from GitHub (default since 2024-10-01)'
  task :pull_requests, [:since_days] => :singleton do |_t, args|
    days_ago = args[:since_days] ? args[:since_days].to_i : 30
    since = Time.now - (days_ago * 24 * 60 * 60)

    puts "Importing pull requests from GitHub updated in the last #{days_ago} days..."

    importer = PullRequestsImporter.new
    result = importer.import(since: since)

    puts 'Successfully imported pull requests from GitHub:'
    puts "  - Imported/Created: #{result[:imported]}"
    puts "  - Updated: #{result[:updated]}"
    puts "  - Errors: #{result[:errors]}"

    # Rake::Task['pull_requests:update_metrics'].invoke if result[:imported] > 0 || result[:updated] > 0
  end

  desc 'Import historical coverage data from Wayback Machine'
  task :coverage_history, [:limit, :start_date, :end_date] do |_t, args|
    limit = args[:limit] ? args[:limit].to_i : nil
    start_date = args[:start_date] ? Date.parse(args[:start_date]) : nil
    end_date = args[:end_date] ? Date.parse(args[:end_date]) : nil

    limit_desc = limit ? "limited to #{limit} records" : 'all available records'
    date_range = [
      start_date ? "from #{start_date}" : nil,
      end_date ? "to #{end_date}" : nil,
    ].compact.join(' ')

    puts "Importing historical coverage data (#{limit_desc}) #{date_range}..."

    importer = WaybackAuthoritiesImporter.new
    count = importer.import_historical_data(limit: limit, start_date: start_date, end_date: end_date)

    puts "Successfully imported #{count} historical coverage records"
  end
end
