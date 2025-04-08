# frozen_string_literal: true

namespace :pull_requests do
  # TODO: - More to import.rake
  desc 'Import pull requests from GitHub (default since 2024-10-01)'
  task :import, [:since_days] => :singleton do |_t, args|
    days_ago = args[:since_days] ? args[:since_days].to_i : 30
    since = Time.now - (days_ago * 24 * 60 * 60)

    puts "Importing pull requests from GitHub updated in the last #{days_ago} days..."

    importer = PullRequestsImporter.new
    result = importer.import(since: since)

    puts 'Successfully imported pull requests from GitHub:'
    puts "  - Imported/Created: #{result[:imported]}"
    puts "  - Updated: #{result[:updated]}"
    puts "  - Errors: #{result[:errors]}"

    Rake::Task['pull_requests:update_metrics'].invoke if result[:imported] > 0 || result[:updated] > 0
  end

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

  # desc 'Update coverage history with PR metrics'
  # task :update_metrics => :singleton do
  #   puts 'Updating coverage history with PR metrics...'
  #
  #   updated = PrMetricsService.update_coverage_history_metrics
  #
  #   puts "Updated #{updated} coverage history records with PR metrics"
  # end

  # Move to generate.rake
  desc 'Generate static pages for pull requests'
  task generate_existing: :singleton do
    puts 'Generating static pages for pull requests...'

    # Generate index page
    index_result = PullRequestsGenerator.generate

    if index_result
      puts "Generated pull requests index page with #{index_result[:pull_requests].size} pull requests"

      # Generate individual pages
      detail_result = PullRequestGenerator.generate
      puts "Generated #{detail_result[:count]} individual pull request pages"
    else
      puts 'No pull requests found to generate pages'
    end
  end
end
