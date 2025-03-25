# frozen_string_literal: true

require 'net/http'
require 'json'

# Service for interacting with GitHub PR API
class GithubPrService
  def check_pr_status(owner, repo, pr_number)
    uri = URI("https://api.github.com/repos/#{owner}/#{repo}/pulls/#{pr_number}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/vnd.github.v3+json'
    request['User-Agent'] = 'PlanniesApp'

    # Add token if available
    request['Authorization'] = "token #{ENV['GITHUB_PERSONAL_TOKEN']}" if ENV['GITHUB_PERSONAL_TOKEN']

    response = http.request(request)

    return JSON.parse(response.body) if response.code == '200'

    error_message = "Error querying GitHub API: #{response.code} #{response.message}"
    if response.code == '403' && response.body.include?('rate limit')
      error_message += "\nRate limit exceeded. Consider using a GitHub token by setting GITHUB_PERSONAL_TOKEN env variable."
    end
    raise StandardError, error_message
  end

  # Check and update the status of open pull requests
  def update_open_prs(limit = nil)
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

        data = check_pr_status(pr.github_owner, pr.github_repo, pr.pr_number)

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

    {
      checked: prs.size,
      updated: updated_count,
      not_found: not_found_count,
      errors: error_count,
    }
  end
end
