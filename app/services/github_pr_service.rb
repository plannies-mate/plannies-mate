# frozen_string_literal: true

require 'net/http'
require 'json'

# Service for interacting with GitHub PR API
class GithubPrService
  # Check PR status from GitHub API
  # @param owner [String] Repository owner
  # @param repo [String] Repository name
  # @param pr_number [Integer] Pull request number
  # @return [Hash] Pull request data from GitHub
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
end
