# frozen_string_literal: true

# Create PullRequest model to cache GitHub PR data
class CreatePullRequests < ActiveRecord::Migration[8.0]
  def change
    # Only MY_GITHUB_USER
    create_table :pull_requests, force: true do |t|
      # repo will set scraper
      t.references :scraper, null: false, foreign_key: true
      t.integer :number, null: false, index: { unique: true }
      t.string :title, null: false
      t.string :state, null: false
      t.boolean :locked, null: false, default: false
      # May disappear
      t.string :head_branch_name, null: false
      t.string :base_branch_name, null: false
      t.datetime :closed_at
      t.datetime :merged_at
      t.string :merge_commit_sha

      # Update triggers
      t.boolean :needs_import, default: false, null: false
      t.datetime :import_triggered_at
      t.string :import_trigger_reason

      # Will set issue: "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
      t.references :issue, null: false, foreign_key: true

      t.timestamps null: false # Use standard Rails timestamps
      t.index [:scraper_id, :number], unique: true, name: 'index_pull_requests_on_scraper_id_and_number'
    end

    # Join tables
    create_table :authorities_pull_requests, id: false do |t|
      t.references :authority, null: false, foreign_key: true, index: false
      t.references :pull_request, null: false, foreign_key: true

      t.index %i[authority_id pull_request_id], unique: true, name: 'index_authorities_prs_on_authority_id_and_pr_id'
    end
  end
end
