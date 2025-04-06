# frozen_string_literal: true

# Create GitHub Labels
class CreateIssueLabels < ActiveRecord::Migration[8.0]
  def change
    # Updated as encountered, deleted when no longer referenced for 30 days
    create_table :issue_labels do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :color
      t.string :description

      t.timestamps null: false
    end
  end
end
