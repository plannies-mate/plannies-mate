# frozen_string_literal: true

require 'octokit'
require_relative '../helpers/application_helper'

# Imports Pull Requests from GitHub
class PullRequestsImporter
  extend ApplicationHelper
  extend GithubBase

  attr_reader :client, :count, :updated, :errors

  def initialize(client = nil)
    @client = client || self.class.create_client
    @count = @updated = @errors = 0
  end

  # Import pull requests for the specified GitHub users
  # @param since [Date] Only fetch PRs updated since this time
  # @return [Hash] Summary of the import
  def import(since: nil)
    @count = @updated = @errors = 0
    org = Constants::PRODUCTION_OWNER
    username = Constants::MY_GITHUB_NAME

    self.class.log "Importing pull requests from #{username} for #{org}"

    # Track all PR IDs to detect deleted PRs - assume PRs more than a year old are rejected
    pr_ids = []

    begin
      # Fetch PRs by this user in the organization
      query = "is:pr author:#{username} org:#{org}"
      search_results = @client.search_issues(query)

      self.class.log "Found #{search_results.items.size} PRs for user #{username}"

      search_results.items.each do |pr_data|
        pull_request = process_pull_request(pr_data)
        pr_ids << pull_request.id if pull_request
      end
    rescue Octokit::Error => e
      @errors += 1
      self.class.log "Error fetching PRs for #{username}: #{e.message}"
    end

    # Clean up PRs that no longer exist
    @removed = 0
    if pr_ids.any?
      @removed = PullRequest.where.not(id: pr_ids)
                            .destroy_all
                            .size
      self.class.log "Removed #{@removed} PRs that no longer exist" if @removed.positive?
    end

    self.class.log "Imported #{@count} PRs, updated #{@updated}, encountered #{@errors} errors"
    { imported: @count, updated: @updated, errors: @errors, removed: @removed }
  end

  private

  # Process a single pull request from the GitHub API
  def process_pull_request(pr_data)
    return if pr_data.draft

    # Extract repository from the PR HTML URL (format: https://github.com/owner/repo/pull/number)
    # Example: https://github.com/planningalerts-scrapers/multiple_masterview/pull/5
    url_parts = pr_data.html_url.split('/')
    return unless url_parts[-4] == Constants::PRODUCTION_OWNER

    repo_name = url_parts[-3]
    scraper = Scraper.find_by(name: repo_name)
    number = pr_data.number
    # Skip PRs for repositories we don't track as scrapers
    unless scraper
      self.class.log "Skipping PR for unknown scraper: #{repo_name}"
      return
    end

    pull_request = PullRequest.find_or_initialize_by(scraper: scraper, number: number)

    is_new = pull_request.new_record?
    attributes = pr_data.to_h.slice(:created_at, :number, :closed_at, :merged_at, :title)
    attributes[:scraper] = scraper

    guess_associated_issue(pull_request, pr_data.title, scraper) unless pull_request.issue_id

    detailed_pr = @client.pull_request(scraper.github_repo_name, number)
    attributes[:base_branch_name] = detailed_pr.base.ref
    attributes[:head_branch_name] = detailed_pr.head.ref

    # Update the record
    if is_new
      pull_request.assign_attributes(attributes)
      pull_request.save!
      @count += 1
      status = (pull_request.merged_at ? ' MERGED' : ' CLOSED') if pull_request.closed_at
      self.class.log "Created new PR: #{pull_request.title}#{status}"
    elsif pull_request.attributes.except('id') != attributes.except('id')
      pull_request.update!(attributes)
      @updated += 1
      self.class.log "Updated PR: #{pull_request.title}"
    end

    pull_request
  end

  # Try to guess which issues this PR is related to based on the PR title and repo name
  def guess_associated_issue(pull_request, title, scraper)
    desc = 'issue for scraper>one authority'
    authority = if scraper.authorities.count == 1
                  scraper.authorities.first
                elsif scraper.name.start_with?('multiple_')
                  desc = 'issue for pull_request.head_branch_name==authority.short_name'
                  Authority.find_by(short_name: pull_request.head_branch_name)
                elsif !scraper.name.start_with?('multiple_')
                  desc = 'issue for scraper.name==authority.short_name'
                  Authority.find_by(short_name: scraper.name)
                end

    issue = Issue.find_by(title: authority.name) if authority
    unless issue
      desc = 'issue for Authority.name == title'
      authority = Authority.find_by(name: title)
      issue = Issue.find_by(title: authority.name) if authority
    end
    unless issue
      desc = 'scraper.authorities>issue.title'
      issues = scraper.authorities
                      .select { |a| title.include?(a.name) }
                      .map { |a| Issue.find_by(title: a.name) }
                      .compact
      issue = issues.first if issues.size == 1
    end
    unless issue
      desc = 'Authorities>issue.title'
      issues = Authority.all
                        .select { |a| title.include?(a.name) }
                        .map { |a| Issue.find_by(title: a.name) }
                        .compact
      issue = issues.first if issues.size == 1
    end
    return unless issue

    pull_request.issue = issue
    self.class.log "Associated PR with issue: #{issue.title} via #{desc}"
  end
end
