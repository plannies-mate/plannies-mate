# frozen_string_literal: true

# Create AuthorityTestResult model to store per-authority test results
class CreateAuthorityTestResults < ActiveRecord::Migration[8.0]
  def change
    create_table :authority_test_results do |t|
      # Links to test_result and authority
      t.references :test_result, null: false, foreign_key: true
      t.references :authority, null: false, foreign_key: true
      
      # The authority label as it appears in the data (can differ from authority.short_name)
      t.string :authority_label
      
      # see error_message for distinction between failed and interrupted
      t.boolean :failed, default: false, null: false
      # Number of records found for this authority
      t.integer :record_count, default: 0
      # Specific error for this authority (truncated to 250 chars)
      t.string :error_message

      t.timestamps null: false
      
      t.index [:test_result_id, :authority_id], unique: true, name: 'idx_authority_test_results'
    end
  end
end
