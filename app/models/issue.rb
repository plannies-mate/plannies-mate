# frozen_string_literal: true

require_relative 'application_record'

# GitHub Label model
#
# == Schema Information
#
# Table name: issues
#
#  id           :integer          not null, primary key
#  closed_at    :datetime
#  html_url     :string
#  locked       :boolean          default(FALSE)
#  milestone    :string
#  state        :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  assignee_id  :integer
#  authority_id :integer
#  user_id      :integer
#
# Indexes
#
#  index_issues_on_assignee_id   (assignee_id)
#  index_issues_on_authority_id  (authority_id)
#  index_issues_on_user_id       (user_id)
#
# Foreign Keys
#
#  assignee_id   (assignee_id => github_users.id)
#  authority_id  (authority_id => authorities.id)
#  user_id       (user_id => github_users.id)
#
class Issue < ApplicationRecord
  belongs_to :assignee, class_name: 'GithubUser', optional: true
  belongs_to :authority, optional: true
  belongs_to :user, class_name: 'GithubUser', optional: true

  has_and_belongs_to_many :assignees,
                          class_name: 'GithubUser',
                          join_table: 'github_users_issues',
                          foreign_key: 'issue_id',
                          association_foreign_key: 'github_user_id'

  has_and_belongs_to_many :labels,
                          class_name: 'IssueLabel',
                          join_table: 'issue_labels_issues',
                          foreign_key: 'issue_id',
                          association_foreign_key: 'issue_label_id'

  IMPORT_KEYS = %i[html_url closed_at locked milestone state title].freeze

  # Assign relevant attributes
  def assign_relevant_attributes(attributes)
    return unless attributes

    relevant_attributes = attributes.slice(*IMPORT_KEYS)
    assign_attributes(relevant_attributes)
  end

  def to_param
    html_url.sub(%r{\A.*/}, '')
  end
end
