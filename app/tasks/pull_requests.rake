# frozen_string_literal: true

namespace :pull_requests do
  # desc 'Import all pull requests from GitHub since 2024-10-01'
  # task :import_all => :singleton do
  #   puts "Importing all pull requests from GitHub since 2024-10-01..."
  #
  #   since = Date.parse('2024-10-01').to_time
  #
  #   importer = PullRequestsImporter.new
  #   result = importer.import(since: since)
  #
  #   puts "Successfully imported all pull requests from GitHub:"
  #   puts "  - Imported/Created: #{result[:imported]}"
  #   puts "  - Updated: #{result[:updated]}"
  #   puts "  - Errors: #{result[:errors]}"
  #
  #   if result[:imported] > 0 || result[:updated] > 0
  #     Rake::Task['pull_requests:update_metrics'].invoke
  #   end
  # end

  desc 'Update coverage history with PR metrics'
  task update_metrics: :singleton do
    puts 'TODO: Updating coverage history with PR metrics...'
    #
    #   updated = PrMetricsService.update_coverage_history_metrics
    #
    #   puts "Updated #{updated} coverage history records with PR metrics"
  end
end
