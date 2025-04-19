# frozen_string_literal: true

require_relative 'application_record'

# Cache for morph.io test results
#
# == Schema Information
#
# Table name: test_results
#
#  id         :integer          not null, primary key
#  commit_sha :string           not null
#  duration   :integer
#  failed     :boolean          default(FALSE), not null
#  name       :string           not null
#  run_at     :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  scraper_id :integer          not null
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
  validates :name, :commit_sha, :run_at, presence: true
  validates :run_at, uniqueness: { scope: :name }

  scope :passed, -> { where(failed: false) }
  scope :failed, -> { where(failed: true) }
  scope :recent, -> { order(run_at: :desc) }

  before_validation :set_scraper

  # Find matching PRs by commit SHA
  def pull_requests
    PullRequest.where(scraper: scraper, head_sha: commit_sha)
  end

  def html_url
    "#{Constants::MORPH_URL}/#{Constants::MY_GITHUB_NAME}/#{name}"
  end

  IMPORT_KEYS = %w[commit_sha failed duration name run_at].freeze

  # Assign relevant attributes
  def assign_relevant_attributes(attributes)
    return unless attributes

    relevant_attributes = attributes.slice(*IMPORT_KEYS)
    assign_attributes(relevant_attributes)

    if attributes['run_time'].to_s.match(/(\d+) minute/)
      assign_attributes duration: ::Regexp.last_match(1).to_i
    elsif attributes['run_time'].to_s.match(/(\d+) hour/)
      assign_attributes duration: ::Regexp.last_match(1).to_i * 60
    end
  end

  def set_scraper
    return unless name.present? && !scraper

    Scraper.all.each do |s|
      if name.start_with?(s.name)
        assign_attributes scraper: s
        break
      end
    end
    return if scraper

    puts "WARNING: Unable to match #{name.inspect} to scrapers: #{Scraper.all.map(&:name).inspect}"
  end
end
