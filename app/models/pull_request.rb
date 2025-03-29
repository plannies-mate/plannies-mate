# frozen_string_literal: true

# == Schema Information
#
# Table name: pull_requests
#
#  id               :integer          not null, primary key
#  closed_at        :datetime
#  html_url         :string           not null
#  locked           :boolean          default(FALSE), not null
#  merge_commit_sha :string
#  merged           :boolean          default(FALSE)
#  merged_at        :datetime
#  number           :integer          not null
#  state            :string           not null
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  issue_id         :integer          not null
#  scraper_id       :integer          not null
#  user_id          :integer          not null
#
# Indexes
#
#  index_pull_requests_on_html_url    (html_url) UNIQUE
#  index_pull_requests_on_issue_id    (issue_id)
#  index_pull_requests_on_scraper_id  (scraper_id)
#  index_pull_requests_on_user_id     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => github_users.id)
#

# Cache for GitHub pull request data
class PullRequest < ApplicationRecord
  include RepoOwnerNumberHtmlUrl

  # Relationships
  has_and_belongs_to_many :authorities
  belongs_to :user, optional: true, class_name: 'GithubUser'
  belongs_to :scraper, required: true

  # Validations
  validates :url, presence: true, uniqueness: true
  validates :created_at, presence: true

  # Scopes
  scope :open, -> { where(closed_at_date: nil) }
  scope :closed, -> { where.not(closed_at_date: nil) }
  scope :merged, -> { where(merged: true) }
  scope :rejected, -> { closed.where(merged: false) }
end
