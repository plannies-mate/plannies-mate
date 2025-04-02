# frozen_string_literal: true

require_relative 'application_record'

# GitHub User model
#
# == Schema Information
#
# Table name: github_users
#
#  id             :integer          not null, primary key
#  avatar_url     :string
#  login          :string           not null
#  site_admin     :boolean          default(FALSE)
#  user_view_type :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_github_users_on_login  (login) UNIQUE
#
class GithubUser < ApplicationRecord
  has_many :created_issues, class_name: 'Issue', foreign_key: 'user_id'
  has_many :assigned_issues, class_name: 'Issue', foreign_key: 'assignee_id'

  # For multiple assignees
  has_and_belongs_to_many :issues, join_table: 'github_users_issues'

  validates :login, presence: true, uniqueness: true

  IMPORT_KEYS = %i[avatar_url html_url login site_admin user_view_type].freeze

  # Assign relevant attributes
  def assign_relevant_attributes(attributes)
    return unless attributes

    relevant_attributes = attributes.slice(*IMPORT_KEYS)
    assign_attributes(relevant_attributes)
  end

  # Link to github issue list for this label
  def issues_url
    base_url = 'https://github.com/planningalerts-scrapers/issues/issues'
    params = { q: "is:issue state:open assignee: \"#{login}\"" }
    uri = URI(base_url)
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end
