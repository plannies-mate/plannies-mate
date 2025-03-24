# frozen_string_literal: true

# Create CoverageHistory table to track authority stats over time
class CreateCoverageHistory < ActiveRecord::Migration[8.0]
  def change
    create_table :coverage_histories, force: true do |t|
      # Use date as natural key with a unique index
      t.date :recorded_on, null: false, index: { unique: true }
      
      # Authority counts
      t.integer :authority_count, null: false, default: 0
      t.integer :broken_authority_count, null: false, default: 0
      
      # Population metrics
      t.integer :total_population, null: false, default: 0
      t.integer :broken_population, null: false, default: 0
      
      # PR impact tracking
      t.integer :pr_count, null: false, default: 0          # Authorities with open PRs
      t.integer :pr_population, null: false, default: 0      # Population affected by open PRs
      t.integer :fixed_count, null: false, default: 0        # Authorities with accepted, closed PRs
      t.integer :fixed_population, null: false, default: 0   # Population affected by fixed PRs
      t.integer :rejected_count, null: false, default: 0     # Authorities with rejected PRs
      t.integer :rejected_population, null: false, default: 0 # Population affected by rejected PRs
      
      t.timestamps
    end
  end
end
