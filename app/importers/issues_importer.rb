# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../helpers/application_helper'
require_relative '../importers/github_base'
require_relative '../matchers/issue_authority_matcher'

# Class to scrape authority list from PlanningAlerts website
class IssuesImporter
  extend ApplicationHelper
  extend GithubBase

  def initialize(client = nil)
    @client = client || self.class.create_client
    @idents = []
    @count = @changed = @has_authority = 0
    @no_authority = []
    @user_changed = @label_changed = @type_changed = 0
  end

  def import
    self.class.log "Importing issues for owner #{Constants::PRODUCTION_OWNER}, repo #{Constants::ISSUES_REPO}"

    repo = "#{Constants::PRODUCTION_OWNER}/#{Constants::ISSUES_REPO}"
    ids = []
    @client.issues(repo, state: 'open').each do |gh_issue|
      @count += 1
      ids << gh_issue.id
      issue = Issue.find_or_initialize_by(id: gh_issue.id)
      issue.assign_relevant_attributes(gh_issue.to_h)

      # Associations
      issue.assignees = gh_issue.assignees&.map { |u| import_user(u) } || []

      issue.labels = gh_issue.labels&.map { |u| import_label(u) } || []

      a = IssueAuthorityMatcher.match(issue.title, issue.labels.pluck(:name))
      if a
        @has_authority += 1
      else
        @no_authority << issue.title
      end
      issue.authority = a

      if issue.changed?
        @changed += 1
        issue.save!
      end
    end

    # Remove closed issues
    Issue.where.not(id: ids).delete_all if ids.any?
    # Remove unused issue types, users, labels

    changed = {
      users: @user_changed,
      labels: @label_changed,
      types: @type_changed,
    }
    self.class.log "Updated #{@changed} of #{@count} issues and #{changed.inspect}.\n  " \
                     "#{@has_authority} issues associated with authorities.\n  " \
                     "Github rate limit remaining: #{@client.rate_limit.remaining}"
    self.class.log "Issues not linked to authority:\n  #{@no_authority.join("\n  ")}"
  end

  def import_user(gh_user)
    return nil unless gh_user

    user = User.find_or_initialize_by(id: gh_user.id)
    user.assign_relevant_attributes(gh_user.to_h)
    if user.changed?
      @user_changed += 1
      user.save!
    end
    user
  end

  def import_label(gh_label)
    return nil unless gh_label

    label = IssueLabel.find_or_initialize_by(id: gh_label.id)
    label.assign_relevant_attributes(gh_label.to_h)
    if label.changed?
      @label_changed += 1
      label.save!
    end
    label
  end
end
