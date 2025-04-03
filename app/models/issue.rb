# frozen_string_literal: true

require_relative 'application_record'

# GitHub Issue model for tracking scraper issues
#
# == Schema Information
#
# Table name: issues
#
#  id                    :integer          not null, primary key
#  closed_at             :datetime
#  import_trigger_reason :string
#  import_triggered_at   :datetime
#  locked                :boolean          default(FALSE), not null
#  needs_generate        :boolean          default(TRUE), not null
#  needs_import          :boolean          default(TRUE), not null
#  number                :integer          not null
#  title                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  authority_id          :integer
#  scraper_id            :integer          not null
#
# Indexes
#
#  index_issues_on_authority_id  (authority_id)
#  index_issues_on_number        (number) UNIQUE
#  index_issues_on_scraper_id    (scraper_id)
#
# Foreign Keys
#
#  authority_id  (authority_id => authorities.id)
#  scraper_id    (scraper_id => scrapers.id)
#
class Issue < ApplicationRecord
  belongs_to :authority, optional: true
  belongs_to :scraper, required: true

  has_and_belongs_to_many :assignees,
                          class_name: 'User',
                          join_table: 'issue_assignees'

  has_and_belongs_to_many :labels,
                          class_name: 'IssueLabel',
                          join_table: 'issue_labels_issues'

  validates :number, presence: true, uniqueness: true
  validates :title, presence: true

  scope :open, -> { where(closed_at: nil) }
  scope :closed, -> { where.not(closed_at: nil) }

  def open?
    closed_at.nil?
  end

  IMPORT_KEYS = %i[html_url closed_at locked milestone state title].freeze

  # Assign relevant attributes
  def assign_relevant_attributes(attributes)
    return unless attributes

    relevant_attributes = attributes.slice(*IMPORT_KEYS)
    assign_attributes(relevant_attributes)
  end

  def to_param
    number.to_s
  end

  def html_url
    "#{scraper.github_url}/pull/#{number}"
  end
end
