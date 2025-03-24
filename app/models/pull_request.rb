# frozen_string_literal: true

# == Schema Information
#
# Table name: pull_requests
#
#  id                  :integer          not null, primary key
#  accepted            :boolean          default(FALSE)
#  closed_at_date      :date
#  github_owner        :string
#  github_repo         :string
#  last_checked_at     :datetime
#  needs_github_update :boolean          default(TRUE)
#  pr_number           :integer
#  title               :string
#  url                 :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  scraper_id          :integer
#
# Indexes
#
#  index_pull_requests_on_scraper_id  (scraper_id)
#  index_pull_requests_on_url         (url) UNIQUE
#

# Cache for GitHub pull request data
class PullRequest < ApplicationRecord
  # Relationships
  has_and_belongs_to_many :authorities

  # Validations
  validates :url, presence: true, uniqueness: true
  validates :created_at, presence: true

  # Scopes
  scope :open, -> { where(closed_at_date: nil) }
  scope :accepted, -> { where.not(closed_at_date: nil).where(accepted: true) }
  scope :rejected, -> { where.not(closed_at_date: nil).where(accepted: false) }
  scope :needs_github_update, -> { where(needs_github_update: true) }

  # Parse GitHub URL
  def parse_github_url
    if url =~ %r{github\.com/([^/]+)/([^/]+)/pull/(\d+)}
      self.github_owner = ::Regexp.last_match(1)
      self.github_repo = ::Regexp.last_match(2)
      self.pr_number = ::Regexp.last_match(3).to_i
      return true
    end
    false
  end

  # Update from GitHub API data
  def update_from_github(github_data)
    # Only update closed status
    if github_data['state'] == 'closed'
      self.closed_at_date = Date.parse(github_data['closed_at'])
      self.accepted = github_data['merged'] == true
      self.needs_github_update = false
    end

    self.last_checked_at = Time.now
    save
  end

  # Import data from YAML 
  def self.import_from_file(yaml_data)
    return { imported: 0, updated: 0 } unless yaml_data.is_a?(Array)

    imported = 0
    updated = 0

    yaml_data.each do |pr_data|
      url = pr_data['url']
      next unless url.present?

      # Find or initialize PR
      pr = find_by(url: url) || new(url: url)

      # Update basic attributes
      pr.title = pr_data['title']
      pr.created_at = Date.parse(pr_data['created_at']) if pr_data['created_at'].present?

      # Update status if in YAML
      if pr_data['closed_at'].present?
        pr.closed_at_date = Date.parse(pr_data['closed_at'])
        pr.accepted = !!pr_data['accepted']
        pr.needs_github_update = false
      elsif !pr.persisted? || pr.closed_at_date.nil?
        # Only mark for update if open or new
        pr.needs_github_update = true
      end

      # Parse GitHub parts from URL
      pr.parse_github_url

      # Try to set PR number directly if available
      pr.pr_number = pr_data['pr_number'].to_i if pr_data['pr_number'].present?

      if pr.new_record?
        imported += 1 if pr.save
      elsif pr.changed? && pr.save
        updated += 1
      end

      # Handle authority associations if we have some
      next unless pr.persisted? && (pr_data['authorities'].is_a?(Array) || pr_data['affected_authorities'].is_a?(Array))

      # Support both field names for backward compatibility
      authority_names = pr_data['authorities'] || pr_data['affected_authorities']
      authorities = Authority.where(short_name: authority_names)

      # Update associations
      pr.authorities = authorities
    end

    { imported: imported, updated: updated }
  end
end
