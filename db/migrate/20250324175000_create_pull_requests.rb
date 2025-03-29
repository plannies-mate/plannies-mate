# frozen_string_literal: true

# Create PullRequest model to cache GitHub PR data
class CreatePullRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :pull_requests, force: true do |t|
      t.integer :number, null: false
      t.string :html_url, null: false, index: { unique: true }
      t.string :title, null: false
      t.string :state, null: false
      t.boolean :locked, null: false, default: false
      t.datetime :closed_at
      t.datetime :merged_at
      t.string :merge_commit_sha

      # Relations
      t.references :user, foreign_key: { to_table: :github_users }, null: false
      # Will set issue: "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
      t.references :issue, null: false
      # repo will set scraper
      t.references :scraper, null: false

      t.timestamps # Use standard Rails timestamps

      t.boolean :merged, default: false
    end

    # Join tables
    create_table :authorities_pull_requests, id: false do |t|
      t.references :authority, null: false, foreign_key: true
      t.references :pull_request, null: false, foreign_key: true

      t.index %i[authority_id pull_request_id], unique: true, name: 'index_authorities_prs_on_authority_id_and_pr_id'
    end

    create_table :github_users_pull_requests, id: false do |t|
      t.references :github_user, null: false, foreign_key: true, index: false
      t.references :pull_request, null: false, foreign_key: true
      t.index %i[github_user_id pull_request_id], unique: true
    end

  end
end
