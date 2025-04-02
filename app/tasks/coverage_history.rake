# frozen_string_literal: true

namespace :coverage_history do
  # TODO: Move to import.rake
  desc 'Import historical coverage data from Wayback Machine working back from to_date till limit records or from_date is reached'
  task :import_historical, [:to_date, :limit, :from_date] do |_t, args|
    limit = args[:limit] ? args[:limit].to_i : nil
    from_date = args[:from_date] ? Date.parse(args[:from_date]) : nil
    to_date = args[:to_date] ? Date.parse(args[:to_date]) : nil

    limit_desc = limit ? "limited to #{limit} records" : 'all available records'
    date_range = [
      from_date ? "from #{from_date}" : nil,
      to_date ? "to #{to_date}" : nil,
    ].compact.join(' ')

    puts "Importing historical coverage data (#{limit_desc}) #{date_range}..."

    importer = WaybackAuthoritiesImporter.new
    count = importer.import_historical_data(limit: limit, from_date: from_date, to_date: to_date)

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
