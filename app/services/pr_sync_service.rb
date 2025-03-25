# frozen_string_literal: true

# Service for synchronizing pull requests between YAML and database
class PrSyncService
  attr_reader :pr_file_path

  def initialize(_pr_file_path = nil)
    @github_service = GithubPrService.new
  end

  # Update PR status from GitHub
  def update_from_github(limit = nil)
    # Only update PRs that need updates
    prs = PullRequest.needs_github_update.order(created_at: :desc)
    prs = prs.limit(limit) if limit

    updated_count = 0
    not_found_count = 0
    error_count = 0

    prs.each do |pr|
      # Skip if we don't have enough GitHub information
      next unless pr.github_owner.present? && pr.github_repo.present? && pr.pr_number.present?

      begin
        puts "Checking #{pr.github_owner}/#{pr.github_repo} PR ##{pr.pr_number}..."

        data = @github_service.check_pr_status(pr.github_owner, pr.github_repo, pr.pr_number)

        # Update PR with data from GitHub
        if pr.update_from_github(data)
          updated_count += 1
          puts "  Updated PR status: #{data['state']}, merged: #{data['merged'] || false}"
        else
          puts '  No status change detected'
        end
      rescue StandardError => e
        if e.message.include?('404')
          not_found_count += 1
          puts '  PR not found on GitHub'

          # Mark as checked to avoid future API calls
          pr.update(last_checked_at: Time.now)
        else
          error_count += 1
          puts "  Error checking PR: #{e.message}"
        end
      end

      # Be nice to GitHub API
      sleep 1 if prs.size > 1
    end

    # Update YAML file with the latest data
    sync_to_yaml if updated_count > 0

    {
      checked: prs.size,
      updated: updated_count,
      not_found: not_found_count,
      errors: error_count,
    }
  end
end
