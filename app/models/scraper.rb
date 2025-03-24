# frozen_string_literal: true

require_relative 'application_record'

# Scraper details collected from authority under the hood details page
#
# == Schema Information
#
# Table name: scrapers
#
#  id           :integer          not null, primary key
#  github_url   :string           not null
#  morph_url    :string           not null
#  scraper_file :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_scrapers_on_morph_url  (morph_url) UNIQUE
#
class Scraper < ApplicationRecord
  validates :morph_url, presence: true, uniqueness: true
  validates :github_url, presence: true

  has_many :authorities

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
