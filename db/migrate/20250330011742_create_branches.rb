# frozen_string_literal: true

# Create PullRequest model to cache GitHub PR data
class CreateBranches < ActiveRecord::Migration[8.0]
  def change
    # We only care about branches for MY_GITHUB_NAME/scraper.name
    create_table :branches, force: true do |t|
      # the associated scraper (otherwise we don't care)
      t.references :scraper, null: false, foreign_key: true
      t.string :name, null: false
      t.references :pull_request, null: true, foreign_key: true

      t.timestamps null: false
      t.index %w[scraper_id name], name: "idx_scraper_branches", unique: true
    end
  end
end
