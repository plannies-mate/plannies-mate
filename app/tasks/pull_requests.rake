# frozen_string_literal: true

require 'yaml'

namespace :pull_requests do
  desc 'Update coverage history with PR metrics'
  task :update_metrics do
    puts 'Updating coverage history with PR metrics...'
    updated = CoverageHistory.update_pr_metrics
    puts "Updated #{updated} coverage history records with PR metrics"
  end

  desc 'Validate the pull requests YAML file'
  task :validate do
    puts 'Validating pull requests YAML file...'

    validator = PrValidatorService.new
    valid = validator.validate_pr_file(
      PrFileService::PR_FILE,
      Authority.pluck(:short_name)
    )

    if valid
      puts "\nValidation successful!"
    else
      puts "\nValidation failed with #{validator.errors.size} errors:"
      validator.errors.each do |error|
        puts "  - #{error}"
      end
      exit 1
    end
  end

  desc 'Import pull requests from YAML to database'
  task :import do
    puts 'Importing pull requests from YAML to database...'

    result = PullRequest.import_from_file

    if result[:imported] > 0 || result[:updated] > 0
      puts 'Successfully imported pull requests from YAML to database.'
      puts "  - Imported: #{result[:imported]}"
      puts "  - Updated: #{result[:updated]}"
    else
      puts 'No changes detected in YAML file.'
    end
  end

  desc 'Update PR status by checking GitHub API'
  task :update_status do
    puts 'Checking GitHub for PR status updates...'

    # First import from YAML to make sure DB has latest manual additions
    import_result = PullRequest.import_from_file

    if import_result[:imported] > 0 || import_result[:updated] > 0
      puts "Imported from YAML: #{import_result[:imported]} new, #{import_result[:updated]} updated"
    end

    # Now update from GitHub
    limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : nil
    limit_desc = limit ? "up to #{limit} PRs" : 'all open PRs'
    puts "Checking GitHub for #{limit_desc}..."

    github_service = GithubPrService.new
    result = github_service.update_open_prs(limit)

    puts 'GitHub check complete:'
    puts "  - Checked: #{result[:checked]} PRs"
    puts "  - Updated: #{result[:updated]} PRs"
    puts "  - Not found: #{result[:not_found]} PRs"
    puts "  - Errors: #{result[:errors]} PRs"

    if result[:updated] > 0
      # Update metrics
      Rake::Task['pull_requests:update_metrics'].invoke
    else
      puts 'No PR status changes found'
    end
  end
end
