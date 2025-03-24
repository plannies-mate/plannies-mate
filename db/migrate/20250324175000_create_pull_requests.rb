# frozen_string_literal: true

# Create PullRequest model to cache GitHub PR data
class CreatePullRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :pull_requests, force: true do |t|
      # GitHub details
      t.string :url, null: false, index: { unique: true }
      t.string :title
      t.references :scraper
      t.integer :pr_number
      t.string :github_owner
      t.string :github_repo

      # Status information
      t.date :closed_at_date
      t.boolean :accepted, default: false
      t.datetime :last_checked_at

      # Cache control
      t.boolean :needs_github_update, default: true

      t.timestamps
    end

    # Join table for PR to authorities relationship
    create_table :authorities_pull_requests, id: false do |t|
      t.references :authority, null: false, foreign_key: true
      t.references :pull_request, null: false, foreign_key: true

      t.index %i[authority_id pull_request_id], unique: true, name: 'index_authorities_prs_on_authority_id_and_pr_id'
    end
  end
end
