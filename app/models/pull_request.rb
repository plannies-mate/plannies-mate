# frozen_string_literal: true

# == Schema Information
#
# Table name: pull_requests
#
#  id                  :integer          not null, primary key
#  closed_at_date      :date
#  last_checked_at     :datetime
#  merged              :boolean          default(FALSE)
#  needs_github_update :boolean          default(TRUE)
#  title               :string
#  url                 :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  github_user_id      :integer
#  scraper_id          :integer
#
# Indexes
#
#  index_pull_requests_on_github_user_id  (github_user_id)
#  index_pull_requests_on_scraper_id      (scraper_id)
#  index_pull_requests_on_url             (url) UNIQUE
#

# Cache for GitHub pull request data
class PullRequest < ApplicationRecord
  # Relationships
  has_and_belongs_to_many :authorities
  belongs_to :github_user, optional: true

  # Validations
  validates :url, presence: true
  validates :github_id, uniqueness: true, allow_nil: true
  validates :created_at, presence: true
  
  # Scopes
  scope :open, -> { where(github_state: 'open') }
  scope :closed, -> { where(github_state: 'closed') }
  scope :merged, -> { where(github_merged: true) }
  scope :rejected, -> { where(github_state: 'closed', github_merged: false) }
  
  # Parse GitHub repository and number from URL
  def parse_github_url
    return unless url =~ %r{github\.com/([^/]+)/([^/]+)/pull/(\d+)}
    
    self.github_repo = "#{Regexp.last_match(1)}/#{Regexp.last_match(2)}"
    self.github_number = Regexp.last_match(3).to_i
  end
  
  # Owner part of repo (e.g., "planningalerts-scrapers")
  def github_owner
    github_repo&.split('/')&.first
  end
  
  # Name part of repo (e.g., "multiple_masterview")
  def github_name
    github_repo&.split('/')&.last
  end
  
  # Before saving, parse the GitHub URL if needed
  before_save :parse_github_url, if: -> { github_repo.blank? || github_number.blank? }
end
