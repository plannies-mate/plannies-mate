# frozen_string_literal: true

namespace :coverage_history do
  desc 'Import historical coverage data from Wayback Machine'
  task :import_historical, [:limit, :start_date, :end_date] do |_t, args|
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

  desc 'Optimize coverage history storage'
  task :optimize do
    puts 'Optimizing coverage history storage...'
    importer = CoverageHistoryImporter.new
    removed = importer.optimize_storage
    puts "Optimization complete. Removed #{removed} redundant records."
  end
end
