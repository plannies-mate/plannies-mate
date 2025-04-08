# frozen_string_literal: true

namespace :coverage_history do
  desc 'Optimize coverage history storage'
  task :optimize do
    puts 'Optimizing coverage history storage...'
    importer = CoverageHistoryImporter.new
    removed = importer.optimize_storage
    puts "Optimization complete. Removed #{removed} redundant records."
  end
end
