# frozen_string_literal: true

require_relative 'application_record'

# Cache for morph.io test results
#
# == Schema Information
#
# Table name: test_results
#
#  id              :integer          not null, primary key
#  commit_sha      :string           not null
#  duration        :integer
#  name            :string           not null
#  records_added   :integer          default(0), not null
#  records_removed :integer          default(0), not null
#  run_at          :datetime         not null
#  running         :boolean          default(FALSE), not null
#  status          :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  scraper_id      :integer          not null
#
# Indexes
#
#  index_test_results_on_git_sha          ("git_sha")
#  index_test_results_on_name_and_run_at  (name,run_at) UNIQUE
#  index_test_results_on_scraper_id       (scraper_id)
#
# Foreign Keys
#
#  scraper_id  (scraper_id => scrapers.id)
#
class TestResult < ApplicationRecord
  belongs_to :scraper
  has_many :authority_test_results, dependent: :destroy
  has_many :authorities, through: :authority_test_results

  # Validations
  validates :name, :git_sha, :status, :run_at, presence: true
  validates :run_at, uniqueness: { scope: :name }

  # Statuses
  PASSED = 'passed'.freeze
  FAILED = 'failed'.freeze
  RUNNING = 'running'.freeze

  scope :passed, -> { where(status: PASSED) }
  scope :failed, -> { where(status: FAILED) }
  scope :running, -> { where(status: RUNNING) }
  scope :recent, -> { order(run_at: :desc) }
  
  # Find matching PRs by commit SHA
  def matching_pull_requests
    PullRequest.where(head_sha: git_sha)
  end
  
  # Determine overall status for display
  def status_summary
    return 'Running' if status == RUNNING
    
    successful = authority_test_results.where(status: 'successful').count
    total = authority_test_results.count
    
    if total.zero?
      'Unknown'
    elsif successful.zero?
      'Bad'
    elsif successful == total
      'Good'
    else
      "#{successful}/#{total}"
    end
  end
  
  # Calculate test duration in human-readable format
  def duration_text
    return nil unless duration
    
    hours = (duration / 3600).floor
    minutes = ((duration % 3600) / 60).floor
    seconds = (duration % 60).round
    
    if hours.positive?
      format('%d:%02d:%02d', hours, minutes, seconds)
    elsif minutes.positive?
      format('%d:%02d', minutes, seconds)
    else
      format('%ds', seconds)
    end
  end
  
  def morph_url
    "#{Constants::MORPH_URL}/#{name}"
  end
end
