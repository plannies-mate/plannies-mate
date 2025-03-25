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
    authorities_scraper = AuthoritiesImporter.new
    authorities_scraper.import
  end

  desc 'Import Open Issues'
  task issues: :singleton do
    fetcher = IssuesImporter.new
    fetcher.import
  end
  
  desc 'Import Pull Requests from GitHub (last 30 days by default)'
  task :pull_requests, [:since_days] => :singleton do |_t, args|
    Rake::Task['pull_requests:import'].invoke(args[:since_days])
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
