# frozen_string_literal: true

require 'octokit'
require_relative '../helpers/application_helper'

# Imports Pull Requests from GitHub
class PullRequestsImporter
  extend ApplicationHelper

  attr_reader :client, :count, :updated, :errors

  def initialize(client = nil)
    @client = client || create_client
    @count = @updated = @errors = 0
  end

  # Create an authenticated GitHub client
  def create_client
    token_name = 'GITHUB_PERSONAL_TOKEN'
    access_token = ENV.fetch(token_name, nil)

    if access_token.nil? && File.size?('.env')
      File.readlines('.env').each do |line|
        access_token = ::Regexp.last_match(1) if line =~ /#{token_name}=(.*)$/
      end
    end

    if access_token
      self.class.log 'Creating GitHub client using personal token...'
      Octokit::Client.new(access_token: access_token, auto_paginate: true)
    else
      self.class.log 'Creating GitHub client without authentication (rate limited to 60 calls per hour)'
      Octokit::Client.new(auto_paginate: true)
    end
  end

  # Import pull requests for the specified GitHub users
  # @param since [Time] Only fetch PRs updated since this time
  # @param users [Array<String>] GitHub usernames to fetch PRs for, defaults to all Users
  # @return [Hash] Summary of the import
  def import(since: nil, users: nil)
    @count = @updated = @errors = 0
    org = 'planningalerts-scrapers'

    # Default to all users in our database
    users ||= User.pluck(:login).compact
    users = [users] if users.is_a?(String)

    # Set default since date if not provided
    since ||= 1.month.ago

    self.class.log "Importing pull requests from GitHub for #{users.size} users since #{since}"

    # Track all PR IDs to detect deleted PRs
    pr_ids = []

    users.each do |username|
      next if username.blank?

      begin
        # Fetch PRs by this user in the organization
        query = "is:pr author:#{username} org:#{org} updated:>#{since.strftime('%Y-%m-%d')}"
        search_results = @client.search_issues(query)

        self.class.log "Found #{search_results.items.size} PRs for user #{username}"

        search_results.items.each do |pr_data|
          process_pull_request(pr_data)
          pr_ids << pr_data.id
        end
      rescue Octokit::Error => e
        @errors += 1
        self.class.log "Error fetching PRs for #{username}: #{e.message}"
      end
    end

    # Clean up PRs that no longer exist
    if pr_ids.any?
      removed = PullRequest.where('updated_at > ?', since)
                           .where.not(id: pr_ids)
                           .destroy_all
                           .size
      self.class.log "Removed #{removed} PRs that no longer exist" if removed > 0
    end

    self.class.log "Imported #{@count} PRs, updated #{@updated}, encountered #{@errors} errors"
    { imported: @count, updated: @updated, errors: @errors }
  end

  private

  # Process a single pull request from the GitHub API
  def process_pull_request(pr_data)
    # Extract repository from the PR HTML URL (format: https://github.com/owner/repo/pull/number)
    # Example: https://github.com/planningalerts-scrapers/multiple_masterview/pull/5
    url_parts = pr_data.html_url.split('/')
    url_parts[-1].to_i

    # Find the scraper
    repo_name = url_parts[-2]
    scraper = Scraper.find_by(name: repo_name)

    # Skip PRs for repositories we don't track as scrapers
    unless scraper
      self.class.log "Skipping PR for unknown scraper: #{repo_name}"
      return
    end

    # Find or initialize the PR record
    pull_request = PullRequest.find_or_initialize_by(url: pr_data.html_url)

    # If this is a new PR, increment the count
    is_new = pull_request.new_record?

    # Find the user
    user = User.find_by(login: pr_data.user.login)
    user ||= User.create!(
      id: pr_data.user.id,
      login: pr_data.user.login,
      html_url: pr_data.user.html_url,
      avatar_url: pr_data.user.avatar_url
    )

    # Extract the PR attributes
    attributes = {
      title: pr_data.title,
      created_at: pr_data.created_at,
      updated_at: pr_data.updated_at,
      user_id: user.id,
      scraper_id: scraper.id,
    }

    # Add closed date if available
    attributes[:closed_at_date] = pr_data.closed_at&.to_date if pr_data.closed_at

    # Determine if it's merged or not
    attributes[:merged] = pr_data.pull_request&.merged_at.present?

    # Update the record
    if is_new
      pull_request.assign_attributes(attributes)
      pull_request.save!
      @count += 1
      self.class.log "Created new PR: #{pull_request.title}"
    elsif pull_request.attributes.except('id') != attributes.except('id')
      pull_request.update!(attributes)
      @updated += 1
      self.class.log "Updated PR: #{pull_request.title}"
    end

    # Auto-associate with authority if possible
    guess_associated_authorities(pull_request, pr_data.title, repo_name) if pull_request.authorities.empty?

    pull_request
  end

  # Try to guess which authorities this PR is related to based on the title and repo
  def guess_associated_authorities(pull_request, title, repo_name)
    # First, check if the repo name matches an authority short_name
    authority = Authority.find_by(short_name: repo_name)
    if authority
      pull_request.authorities << authority
      self.class.log "Associated PR with authority: #{authority.short_name}"
      return
    end

    # Try to match from the title using the matcher
    if defined?(IssueAuthorityMatcher) && IssueAuthorityMatcher.respond_to?(:match)
      authority = IssueAuthorityMatcher.match(title, [])
      if authority
        pull_request.authorities << authority
        self.class.log "Associated PR with authority via title match: #{authority.short_name}"
        return
      end
    end

    # For "multiple_*" scrapers, try to find authorities using that scraper
    return unless repo_name.start_with?('multiple_')

    scraper = Scraper.find_by(name: repo_name)
    return unless scraper&.authorities&.any?
    # Don't automatically add too many authorities
    return unless scraper.authorities.size <= 5

    pull_request.authorities = scraper.authorities
    self.class.log "Associated PR with #{scraper.authorities.size} authorities from multiple scraper"
  end
end
