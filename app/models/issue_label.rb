# frozen_string_literal: true

require_relative 'application_record'

# GitHub Label model
#
# == Schema Information
#
# Table name: issue_labels
#
#  id          :integer          not null, primary key
#  color       :string
#  description :string
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_issue_labels_on_name  (name) UNIQUE
#
class IssueLabel < ApplicationRecord
  has_and_belongs_to_many :issues, join_table: 'issue_labels_issues'

  validates :name, presence: true, uniqueness: true

  IMPORT_KEYS = %i[color description name].freeze

  # Assign relevant attributes
  def assign_relevant_attributes(attributes)
    return unless attributes

    relevant_attributes = attributes.slice(*IMPORT_KEYS)
    assign_attributes(relevant_attributes)
  end

  # Link to github issue list for this label
  def issues_url
    base_url = 'https://github.com/planningalerts-scrapers/issues/issues'
    params = { q: "is:issue state:open label:\"#{name}\"" }
    uri = URI(base_url)
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end
