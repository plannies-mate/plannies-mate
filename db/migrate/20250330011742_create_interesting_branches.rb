# frozen_string_literal: true

# Create PullRequest model to cache GitHub PR data
class CreateInterestingBranches < ActiveRecord::Migration[8.0]
  def change
    # We only care about branches for MY_GITHUB_NAME/scraper.name
    create_table :interesting_branches, force: true do |t|
      # the associated scraper (otherwise we don't care)
      t.references :scraper, null: false, foreign_key: true
      t.string :branch_name, null: false
      t.datetime :last_commit_at, null: false
      t.string :last_commit_sha
      # the pull request IF there is one
      t.references :pull_request, null: true, foreign_key: true

      t.timestamps null: false
      t.index %w[html_url branch_name], name: "index_interesting_branches_on_html_url_and_branch", unique: true
    end
  end
end
