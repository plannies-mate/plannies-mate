# frozen_string_literal: true

require_relative 'application_record'

# Authority details collected from various sources, uniquely identified by short_name
#
# == Schema Information
#
# Table name: authorities
#
#  id                  :integer          not null, primary key
#  added_on            :date             not null
#  authority_label     :string
#  broken_score        :integer
#  delisted_on         :date
#  last_import_log     :text
#  last_received       :date
#  median_per_week     :integer          default(0), not null
#  month_count         :integer          default(0), not null
#  name                :string           not null
#  needs_generate      :boolean          default(TRUE), not null
#  needs_import        :boolean          default(TRUE), not null
#  population          :integer
#  possibly_broken     :boolean          default(FALSE), not null
#  query_error         :string
#  query_owner         :string
#  query_url           :string
#  short_name          :string           not null
#  state               :string(3)
#  total_count         :integer          default(0), not null
#  update_reason       :string
#  update_requested_at :datetime
#  week_count          :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  scraper_id          :integer
#
# Indexes
#
#  index_authorities_on_broken_score  (broken_score)
#  index_authorities_on_scraper_id    (scraper_id)
#  index_authorities_on_short_name    (short_name) UNIQUE
#
# Foreign Keys
#
#  scraper_id  (scraper_id => scrapers.id)
#
class Authority < ApplicationRecord
  has_and_belongs_to_many :coverage_histories_when_broken,
                          class_name: 'CoverageHistory',
                          join_table: 'broken_authority_histories'

  validates :short_name, presence: true, uniqueness: true
  validates :name, presence: true

  belongs_to :scraper, optional: true
  has_many :issues

  scope :working, -> { where(possibly_broken: false) }
  scope :broken, -> { where(possibly_broken: true) }

  scope :active, -> { where(delisted_on: nil) }

  # Format for display in UI
  def to_s
    "#{name} (#{state})"
  end

  def authorities_url
    self.class.authorities_url(short_name || 'nil')
  end

  def self.authorities_url(short_name = nil)
    "#{Constants::AUTHORITIES_URL}#{short_name ? "/#{short_name}" : ''}"
  end

  IMPORT_KEYS =
    %w[short_name state name possibly_broken population
       last_received week_count month_count total_count added_on median_per_week stats_etag
       last_import_log details_etag].freeze

  # Assign relevant attributes
  def assign_relevant_attributes(attributes)
    return unless attributes

    relevant_attributes = attributes.slice(*IMPORT_KEYS)
    assign_attributes(relevant_attributes)
  end

  def to_param
    short_name || 'nil'
  end

  def issues_url
    base_url = 'https://github.com/planningalerts-scrapers/issues/issues'
    params = { q: "is:issue state:open #{name}" }
    uri = URI(base_url)
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def mine?
    issues.any?(&:mine?)
  end

  def open_pull_requests?
    issues.any?(&:open_pull_requests?)
  end

  def blocked?
    issues.all?(&:blocked?)
  end

  def others?
    !mine? && issues.any?(&:others?)
  end
end
