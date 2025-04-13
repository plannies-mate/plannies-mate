# frozen_string_literal: true

# Cache for GitHub pull request data
#
# == Schema Information
#
# Table name: pull_requests
#
#  id               :integer          not null, primary key
#  base_branch_name :string           not null
#  closed_at        :datetime
#  head_branch_name :string           not null
#  locked           :boolean          default(FALSE), not null
#  merged_at        :datetime
#  number           :integer          not null
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  issue_id         :integer
#  scraper_id       :integer          not null
#
# Indexes
#
#  index_pull_requests_on_issue_id               (issue_id)
#  index_pull_requests_on_scraper_id             (scraper_id)
#  index_pull_requests_on_scraper_id_and_number  (scraper_id,number) UNIQUE
#
# Foreign Keys
#
#  issue_id    (issue_id => issues.id)
#  scraper_id  (scraper_id => scrapers.id)
#
class PullRequest < ApplicationRecord
  has_and_belongs_to_many :assignees,
                          join_table: 'pull_request_assignees',
                          class_name: 'User'
  belongs_to :issue, optional: true
  belongs_to :scraper, required: true
  has_one :branch, dependent: :nullify

  # Validations
  validates :base_branch_name,
            :head_branch_name,
            :number,
            :title,
            presence: true

  validates :number, uniqueness: { scope: :scraper_id }

  scope :open, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }
  scope :merged, -> { where.not(merged_at: nil) }
  scope :rejected, -> { closed.where(merged_at: nil) }

  def open?
    closed_at.nil?
  end

  def merged?
    !merged_at.nil?
  end

  def rejected?
    !open? && !merged?
  end

  def html_url
    "#{scraper.github_url}/pull/#{number}"
  end
end
