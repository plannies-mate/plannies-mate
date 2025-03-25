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
  # @param users [Array<String>] GitHub usernames to fetch PRs for, defaults to all GithubUsers
  # @return [Hash] Summary of the import
  def import(since: nil, users: nil)
    @count = @updated = @errors = 0
    org = 'planningalerts-scrapers'
    
    # Default to all users in our database
    users ||= GithubUser.pluck(:login).compact
    users = [users] if users.is_a?(String)
    
    # Set default since date if not provided
    since ||= Date.parse('2024-10-01').to_time
    
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
      removed = PullRequest.where('github_updated_at > ?', since)
                           .where.not(github_id: pr_ids)
                           .destroy_all
                           .size
      self.class.log "Removed #{removed} PRs that no longer exist" if removed > 0
    end
    
    self.class.log "Imported #{@count} PRs, updated #{@updated} PRs, encountered #{@errors} errors"
    { imported: @count, updated: @updated, errors: @errors }
  end
  
  private
  
  # Process a single pull request from the GitHub API
  def process_pull_request(pr_data)
    # Extract repository from the repo URL (format: https://github.com/owner/repo/pull/number)
    repo = pr_data.repository_url.split('/').last(2).join('/')
    
    # Find or initialize the PR record
    pull_request = PullRequest.find_or_initialize_by(github_id: pr_data.id)
    
    # If this is a new PR, increment the count
    is_new = pull_request.new_record?
    
    # Extract the PR attributes
    attributes = {
      title: pr_data.title,
      url: pr_data.html_url,
      github_repo: repo,
      github_number: pr_data.number,
      github_state: pr_data.state,
      github_merged: pr_data.pull_request&.merged_at.present?,
      github_updated_at: pr_data.updated_at,
      closed_at_date: pr_data.closed_at ? Date.parse(pr_data.closed_at.to_s) : nil,
      accepted: pr_data.pull_request&.merged_at.present?
    }
    
    # Find the user
    user_login = pr_data.user&.login
    if user_login.present?
      user = GithubUser.find_by(login: user_login)
      attributes[:github_user_id] = user.id if user
    end
    
    # Auto-associate with authority if possible
    if is_new && pull_request.authorities.empty?
      guess_associated_authorities(pull_request, pr_data.title, repo)
    end
    
    # Update the record if anything changed
    changed = pull_request.assign_attributes(attributes)
    
    if pull_request.new_record? || pull_request.changed?
      pull_request.save!
      @count += 1 if is_new
      @updated += 1 unless is_new
    end
  end
  
  # Try to guess which authorities this PR is related to based on the title and repo
  def guess_associated_authorities(pull_request, title, repo)
    # Extract repo name without owner
    repo_name = repo.split('/').last
    
    # First, check if the repo name matches an authority short_name
    authority = Authority.find_by(short_name: repo_name)
    if authority
      pull_request.authorities << authority
      return
    end
    
    # Try to match from the title using the matcher
    if defined?(IssueAuthorityMatcher) && IssueAuthorityMatcher.respond_to?(:match)
      authority = IssueAuthorityMatcher.match(title, [])
      if authority
        pull_request.authorities << authority
        return
      end
    end
    
    # For "multiple_*" scrapers, try to find authorities using that scraper
    if repo_name.start_with?('multiple_')
      scraper = Scraper.find_by(name: repo_name)
      if scraper&.authorities&.any?
        # Don't automatically add too many authorities
        if scraper.authorities.size <= 5
          pull_request.authorities = scraper.authorities
        end
      end
    end
  end
end
