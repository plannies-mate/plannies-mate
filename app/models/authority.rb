# frozen_string_literal: true

require_relative 'application_record'

# Authority details collected from various sources, uniquely identified by short_name
#
# == Schema Information
#
# Table name: authorities
#
#  id                    :integer          not null, primary key
#  added_on              :date
#  admin_url             :string
#  import_count          :integer          default(0), not null
#  import_trigger_reason :string
#  import_triggered_at   :datetime
#  imported_on           :string
#  ip_addresses          :string
#  last_log              :text
#  last_received         :date
#  median_per_week       :integer          default(0), not null
#  month_count           :integer          default(0), not null
#  name                  :string           not null
#  needs_generate        :boolean          default(TRUE), not null
#  needs_import          :boolean          default(TRUE), not null
#  population            :integer
#  possibly_broken       :boolean          default(FALSE), not null
#  query_domains         :string
#  removed_on            :date
#  short_name            :string           not null
#  state                 :string
#  total_count           :integer          default(0), not null
#  website_url           :string
#  week_count            :integer          default(0), not null
#  whois_names           :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  scraper_id            :integer
#
# Indexes
#
#  index_authorities_on_scraper_id  (scraper_id)
#  index_authorities_on_short_name  (short_name) UNIQUE
#
# Foreign Keys
#
#  scraper_id  (scraper_id => scrapers.id)
#
class Authority < ApplicationRecord
  validates :short_name, presence: true, uniqueness: true
  validates :name, :url, :scraper, presence: true

  belongs_to :scraper
  has_many :issues

  scope :working, -> { where(possibly_broken: false) }
  scope :broken, -> { where(possibly_broken: true) }

  # Find an authority by its short_name
  def self.find_by_short_name(short_name)
    find_by(short_name: short_name)
  end

  # Format for display in UI
  def to_s
    "#{name} (#{state})"
  end

  IMPORT_KEYS =
    %w[short_name state name url possibly_broken population
       last_received week_count month_count total_count added_on median_per_week stats_etag
       last_log import_count imported_on details_etag].freeze

  # Assign relevant attributes
  def assign_relevant_attributes(attributes)
    return unless attributes

    this_scraper = Scraper.import_from_hash(attributes)
    self.scraper = this_scraper if this_scraper && scraper != this_scraper
    relevant_attributes = attributes.slice(*IMPORT_KEYS)
    assign_attributes(relevant_attributes)
  end

  def to_parem
    short_name
  end

  def issues_url
    base_url = 'https://github.com/planningalerts-scrapers/issues/issues'
    params = { q: "is:issue state:open #{name}" }
    uri = URI(base_url)
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end
