# frozen_string_literal: true

require_relative 'concerns/repo_owner_number_html_url'

# == Schema Information
#
# Table name: pull_requests
#
#  id                    :integer          not null, primary key
#  base_branch_name      :string           not null
#  closed_at             :datetime
#  head_branch_name      :string           not null
#  import_trigger_reason :string
#  import_triggered_at   :datetime
#  locked                :boolean          default(FALSE), not null
#  merge_commit_sha      :string
#  merged_at             :datetime
#  needs_import          :boolean          default(FALSE), not null
#  number                :integer          not null
#  state                 :string           not null
#  title                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  issue_id              :integer          not null
#  scraper_id            :integer          not null
#
# Indexes
#
#  index_pull_requests_on_issue_id               (issue_id)
#  index_pull_requests_on_number                 (number) UNIQUE
#  index_pull_requests_on_scraper_id             (scraper_id)
#  index_pull_requests_on_scraper_id_and_number  (scraper_id,number) UNIQUE
#
# Foreign Keys
#
#  issue_id    (issue_id => issues.id)
#  scraper_id  (scraper_id => scrapers.id)
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
