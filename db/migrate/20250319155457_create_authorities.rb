# frozen_string_literal: true

# Create Planning Authorities
class CreateAuthorities < ActiveRecord::Migration[8.0]
  def change
    create_table :authorities, force: true do |t|
      # Basic authority information
      t.string :short_name, null: false, index: { unique: true }
      t.string :state
      t.string :name, null: false
      t.boolean :possibly_broken, default: false, null: false
      t.integer :population
      # date authority is no longer listed
      t.date :removed_on

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

      # Details from issue - project link
      # The website for the council (from associated issue - project link details)
      t.string :website_url
      # The PA admin url
      t.string :admin_url

      # Details from repo files => scraper.* and dns / whois lookup
      # comma seperated list of domains used in code
      t.string :query_domains
      # comma seperated ip addresses these domains resolve to (or "FAIL" if DNS lookup failed)
      t.string :ip_addresses
      # whois descr
      t.string :whois_names

      # requires import of details, stats pages and github details
      t.boolean :needs_import, default: true, null: false
      # generate after needs_import
      t.boolean :needs_generate, default: true, null: false
      t.datetime :import_triggered_at
      t.string :import_trigger_reason

      t.timestamps null: false
    end
  end
end
