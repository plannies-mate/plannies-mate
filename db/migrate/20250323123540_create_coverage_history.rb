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
      
      # PR impact tracking - recalculate if PR - authorities association changes
      t.integer :pr_count, null: false, default: 0          # Authorities with open PRs
      t.integer :pr_population, null: false, default: 0      # Population affected by open PRs
      t.integer :fixed_count, null: false, default: 0        # Authorities with accepted, closed PRs
      t.integer :fixed_population, null: false, default: 0   # Population affected by fixed PRs
      t.integer :rejected_count, null: false, default: 0     # Authorities with rejected PRs
      t.integer :rejected_population, null: false, default: 0 # Population affected by rejected PRs
      
      t.timestamps null: false
    end

    # Add a new association table
    create_table :broken_authority_histories, id: false do |t|
      t.references :authority, null: false, foreign_key: true, index: false
      t.references :coverage_history, null: false, foreign_key: true
      t.index [:authority_id, :coverage_history_id], unique: true, name: 'idx_broken_authority_histories'
    end
  end
end
