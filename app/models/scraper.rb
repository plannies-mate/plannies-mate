# frozen_string_literal: true

require_relative 'application_record'

# Scraper details collected from authority under the hood details page
#
# == Schema Information
#
# Table name: scrapers
#
#  id               :integer          not null, primary key
#  authorities_path :string
#  broken_score     :integer
#  default_branch   :string           default("master"), not null
#  delisted_on      :date
#  name             :string           not null
#  scraper_path     :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_scrapers_on_broken_score  (broken_score)
#  index_scrapers_on_name          (name) UNIQUE
#
class Scraper < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :authorities

  scope :active, -> { where(delisted_on: nil) }

  def morph_url(owner = nil)
    self.class.morph_url(owner, name: name || 'nil')
  end

  def self.morph_url(owner = nil, name: nil)
    owner ||= Constants::PRODUCTION_OWNER
    "#{Constants::MORPH_URL}/#{owner}#{name ? "/#{name}" : ''}"
  end

  def github_repo_name(owner = nil)
    owner ||= Constants::PRODUCTION_OWNER
    "#{owner}/#{to_param}"
  end

  def github_url(owner = nil)
    "#{Constants::GITHUB_URL}/#{github_repo_name(owner)}"
  end

  def to_s
    name
  end

  def to_param
    name || 'nil'
  end

  IMPORT_KEYS = %w[name].freeze

  def self.import_from_hash(data)
    return nil if data['name'].blank?

    scraper = find_by(name: data['name']) || new
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
