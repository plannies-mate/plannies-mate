# frozen_string_literal: true

# Add SHA fields to PullRequests for linking with test results
class AddShaToPullRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :pull_requests, :head_sha, :string
    add_column :pull_requests, :base_sha, :string
    
    add_index :pull_requests, :head_sha

    execute 'UPDATE pull_requests SET head_sha = "missing", base_sha = "missing"'
    change_column :pull_requests, :head_sha, :string, null: false
    change_column :pull_requests, :base_sha, :string, null: false
  end
end
