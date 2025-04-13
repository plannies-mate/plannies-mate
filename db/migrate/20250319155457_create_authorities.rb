# frozen_string_literal: true

# Create Planning Authorities
class CreateAuthorities < ActiveRecord::Migration[8.0]
  def change
    create_table :authorities, force: true do |t|
      # Basic authority information
      t.string :short_name, null: false, index: { unique: true }
      # State of Australia, not open/closed
      t.string :state, limit: 3
      t.string :name, null: false
      t.boolean :possibly_broken, default: false, null: false
      t.integer :population
      # date authority is no longer listed
      t.date :delisted_on

      # Stats from Information page (Not checked for historical lists)
      t.date :last_received
      t.integer :week_count, default: 0, null: false
      t.integer :month_count, default: 0, null: false
      t.integer :total_count, default: 0, null: false
      # Use first observed in wayback if needed
      t.date :added_on, null: false
      t.integer :median_per_week, default: 0, null: false

      # "Under the hood" Details data (Not checked for historical lists)
      t.references :scraper, null: true, foreign_key: true
      t.text :last_import_log

      # Details from scraper.authorities_path file and dns / whois lookup
      # Authority label used in scraper for data records if different to name
      t.string :authority_label
      # Query url in authorities_path
      t.string :query_url
      # error message why query failed (DNS lookup, port closed, timeout etc)
      t.string :query_error
      # Who owns the IP numbers (either from CDN CNAME or from whois organisation / descr)
      t.string :query_owner

      # A score impact of it being broken
      t.integer :broken_score, index: true, null: true

      t.timestamps null: false
    end
  end
end
