# frozen_string_literal: true

# Create TestResult model to store morph.io test run results
class CreateTestResults < ActiveRecord::Migration[8.0]
  def change
    create_table :test_results do |t|
      # The name as listed on https://morph.io/ianheggie-oaf
      t.string :name, null: false
      t.references :scraper, null: false, foreign_key: true
      # Git commit SHA first listed in History
      t.string :commit_sha, null: false
      # one or more authorities failed
      t.boolean :failed, default: false, null: false
      # When the test was last run
      t.datetime :run_at, null: false
      # How long the test took (in minutes, 1-2 significant digits)
      t.integer :duration

      t.timestamps null: false
      
      t.index [:name, :run_at], unique: true
      t.index :git_sha
    end
  end
end
