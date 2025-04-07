# frozen_string_literal: true

# Create PullRequest model to cache GitHub PR data
class CreatePullRequests < ActiveRecord::Migration[8.0]
  def change
    # Only save pull requests created by MY_GITHUB_USER for repos owned by PRODUCTION_OWNER
    # Recorded to a fix is available (not6 closed or merged) or a fix have been applied (merged)
    create_table :pull_requests, force: true do |t|
      # repo will set scraper
      t.references :scraper, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :title, null: false
      t.boolean :locked, null: false, default: false
      t.string :head_branch_name, null: false
      t.string :base_branch_name, null: false
      t.datetime :closed_at
      t.datetime :merged_at
      # if draft or I am one of the assignees (doesn't count when needs_review)
      t.boolean :needs_review, null: false, default: false

      # requires import of github details (because of webhook, manual request or nightly)
      t.boolean :needs_import, default: true, null: false
      # generate after needs_import
      t.boolean :needs_generate, default: true, null: false
      t.datetime :update_requested_at
      t.string :update_reason

      # If we can work it out ...
      t.references :issue, null: true, foreign_key: true

      t.timestamps null: false # Use standard Rails timestamps
      t.index [:scraper_id, :number], unique: true, name: 'index_pull_requests_on_scraper_id_and_number'
    end

    # This is used with summary and lists to indicate a fix is available for a possibly broken authority
    create_table :pull_request_assignees, id: false do |t|
      t.references :pull_request, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true

      t.index %i[pull_request_id user_id], unique: true, name: 'idx_pull_request_assignees'
    end
  end
end
