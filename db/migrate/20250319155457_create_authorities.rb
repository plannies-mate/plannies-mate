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

      # Stats data (Not checked for historical lists)
      t.date :last_received
      t.integer :week_count, default: 0, null: false
      t.integer :month_count, default: 0, null: false
      t.integer :total_count, default: 0, null: false
      t.date :added_on
      t.integer :median_per_week, default: 0, null: false

      # Details data (Not checked for historical lists)
      t.references :scraper, null: true, foreign_key: true
      t.text :last_log
      t.integer :import_count, default: 0, null: false
      t.string :imported_on

      # Details from repo files => scraper.* and dns / whois lookup
      # Authority label used in scraper for data records if different to name
      t.string :authority_label
      # unique list of domains found in code (JSON)
      t.text :query_domains
      # unique list of ip addresses these domains resolve to (or "FAIL" if DNS lookup failed) (JSON)
      t.text :ip_addresses
      # unique list of whois descr (JSON)
      t.text :whois_names

      # A score impact of it being broken
      t.integer :broken_score, index: true, null: true

      # requires import of details, stats pages and github details
      t.boolean :needs_import, default: true, null: false
      # generate after needs_import
      t.boolean :needs_generate, default: true, null: false
      t.datetime :update_requested_at
      t.string :update_reason

      t.timestamps null: false
    end
  end
end
