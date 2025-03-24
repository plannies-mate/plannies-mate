# frozen_string_literal: true

# Create Planning Authorities
class CreateAuthorities < ActiveRecord::Migration[8.0]
  def change
    create_table :authorities, force: true do |t|
      # Basic authority information
      t.string :short_name, null: false, index: { unique: true }
      t.string :state
      t.string :name, null: false
      t.string :url, null: false
      # The website for the council
      t.string :website_url
      # The domain used to send queries to
      t.string :query_domain
      # The PA admin url
      t.string :admin_url
      t.boolean :possibly_broken, default: false, null: false
      t.integer :population

      # Stats data
      t.date :last_received
      t.integer :week_count, default: 0, null: false
      t.integer :month_count, default: 0, null: false
      t.integer :total_count, default: 0, null: false
      t.date :added_on
      t.integer :median_per_week, default: 0, null: false

      # Details data
      t.references :scraper, null: false, foreign_key: true
      t.text :last_log
      t.integer :import_count, default: 0, null: false
      t.string :imported_on

      t.timestamps
    end
  end
end
