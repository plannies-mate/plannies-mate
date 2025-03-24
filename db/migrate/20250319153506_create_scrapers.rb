# frozen_string_literal: true

# Create Planning Scrapers
class CreateScrapers < ActiveRecord::Migration[8.0]
  def change
    create_table :scrapers, force: true do |t|
      # Basic morph scraper details from authority details
      t.string :morph_url, null: false, index: { unique: true }
      t.string :github_url, null: false
      t.string :scraper_file

      t.timestamps
    end
  end
end
