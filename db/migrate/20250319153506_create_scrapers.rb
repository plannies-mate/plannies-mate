# frozen_string_literal: true

# Create Planning Scrapers
class CreateScrapers < ActiveRecord::Migration[8.0]
  def change
    create_table :scrapers, force: true do |t|
      # github and morph primary key of owner + '/' + repo
      t.string :name, null: false, index: { unique: true }
      t.string :default_branch, null: false, default: "master"

      # Details for classification and to
      # Path to scraper.rb / py etc
      t.string :scraper_path
      # Path to file that contains the list of authorities and their query domains.
      # Typically custom scrapes will use the same file
      t.string :authorities_path

      # A score impact of it being broken
      t.integer :broken_score, index: true, null: true

      # requires import of github details (because of webhook, manual request or nightly)
      t.boolean :needs_import, default: true, null: false
      # generate after needs_import
      t.boolean :needs_generate, default: true, null: false
      t.datetime :update_requested_at
      t.string :update_reason

      t.timestamps null: false
    end
  end
end
