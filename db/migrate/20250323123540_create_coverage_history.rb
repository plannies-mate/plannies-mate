# frozen_string_literal: true

# Create CoverageHistory table to track authority stats over time
class CreateCoverageHistory < ActiveRecord::Migration[8.0]
  def change
    create_table :coverage_histories, force: true do |t|
      # Use date as natural key with a unique index
      t.date :recorded_on, null: false, index: { unique: true }

      # Also Signals data came from wayback archive
      t.string :wayback_url, null: true, index: { unique: true }

      # Authority counts
      t.integer :authority_count, null: false, default: 0
      t.integer :broken_authority_count, null: false, default: 0

      # Population metrics
      t.integer :total_population, null: false, default: 0
      t.integer :broken_population, null: false, default: 0

      t.json :authority_stats, default: {}, null: false

      t.timestamps null: false
    end
  end
end
