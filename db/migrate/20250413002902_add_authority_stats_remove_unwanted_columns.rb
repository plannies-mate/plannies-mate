class AddAuthorityStatsRemoveUnwantedColumns < ActiveRecord::Migration[7.0]
  def change
    # Add new JSON column for authority stats
    # Using :json type which Rails maps appropriately based on the database
    # (TEXT for SQLite, jsonb for PostgreSQL)
    add_column :coverage_histories, :authority_stats, :json, default: {}, null: false
    
    # Remove unwanted columns
    remove_column :coverage_histories, :pr_count
    remove_column :coverage_histories, :pr_population
    remove_column :coverage_histories, :fixed_count
    remove_column :coverage_histories, :fixed_population
    remove_column :coverage_histories, :rejected_count
    remove_column :coverage_histories, :rejected_population
  end
end
