# frozen_string_literal: true

require_relative 'application_record'

# Scraper details collected from authority under the hood details page
#
# == Schema Information
#
# Table name: scrapers
#
#  id                  :integer          not null, primary key
#  authorities_path    :string
#  default_branch      :string           default("master"), not null
#  name                :string           not null
#  needs_generate      :boolean          default(TRUE), not null
#  needs_import        :boolean          default(TRUE), not null
#  scraper_path        :string
#  update_reason       :string
#  update_requested_at :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_scrapers_on_name  (name) UNIQUE
#
class Scraper < ApplicationRecord
  validates :morph_url, presence: true, uniqueness: true
  # @example: https://github.com/planningalerts-scrapers/multiple_icon
  validates :github_url, presence: true

  has_many :authorities

  def repo
    github_url.split('/')[-1]
  end

  # Extract owner from html_url, "planningalerts-scrapers" in the examples above
  def owner
    github_url.split('/')[-2]
  end

  def to_s
    gh_name = File.basename(github_url)
    if name == gh_name
      name
    else
      "#{name} (#{gh_name})"
    end
  end

  def to_param
    File.basename(morph_url)
  end

  alias name to_param

  IMPORT_KEYS = %w[morph_url github_url].freeze

  def self.import_from_hash(data)
    return nil if data['morph_url'].blank?

    scraper = find_by(morph_url: data['morph_url']) || new
    scraper.assign_relevant_attributes(data)
    scraper.save!
    scraper
  end

  def assign_relevant_attributes(data)
    return unless data

    relevant_attributes = data.slice(*IMPORT_KEYS)
    assign_attributes(relevant_attributes)
  end
end
