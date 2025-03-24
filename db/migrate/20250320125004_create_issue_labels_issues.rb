# frozen_string_literal: true

# Create join table for issues and labels
class CreateIssueLabelsIssues < ActiveRecord::Migration[8.0]
  def change
    # Use Rails naming convention for HABTM join tables (alphabetical order of table names)
    create_table :issue_labels_issues, id: false do |t|
      t.references :issue_label, null: false, foreign_key: true, index: false
      t.references :issue, null: false, foreign_key: true
    end

    add_index :issue_labels_issues, %i[issue_label_id issue_id], unique: true
  end
end
