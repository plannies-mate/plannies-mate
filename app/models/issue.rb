# frozen_string_literal: true

require_relative 'application_record'
require_relative 'concerns/repo_owner_number_html_url'

# GitHub Label model
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
#  state                 :string           not null
#  title                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  authority_id          :integer
#  scraper_id            :integer
#  user_id               :integer          not null
#
# Indexes
#
#  index_issues_on_authority_id  (authority_id)
#  index_issues_on_number        (number) UNIQUE
#  index_issues_on_scraper_id    (scraper_id)
#  index_issues_on_user_id       (user_id)
#
# Foreign Keys
#
#  authority_id  (authority_id => authorities.id)
#  scraper_id    (scraper_id => scrapers.id)
#  user_id       (user_id => github_users.id)
#
class Issue < ApplicationRecord
  include RepoOwnerNumberHtmlUrl

  belongs_to :authority, required: true
  belongs_to :user, class_name: 'GithubUser', required: true

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
