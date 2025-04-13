# frozen_string_literal: true

# Create Issues
class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      # Issues are owned by PRODUCTION_OWNER in ISSUE_REPO
      t.integer :number, null: false, index: { unique: true }
      t.string :title, null: false
      t.boolean :locked, null: false, default: false
      t.datetime :closed_at

      # Relations (optional)
      t.references :authority, foreign_key: true, null: true
      t.references :scraper, foreign_key: true, null: true

      t.timestamps null: false # Use standard Rails timestamps
    end

    # Labels are kept so they can be reported
    create_table :issue_labels_issues, id: false do |t|
      t.references :issue_label, null: false, foreign_key: true, index: false
      t.references :issue, null: false, foreign_key: true
      t.index %i[issue_label_id issue_id], unique: true
    end

    # Assignees are kept - If I am an assignee then the task is regarded as in progress
    create_table :issue_assignees, id: false do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :issue, null: false, foreign_key: true
      t.index %i[user_id issue_id], unique: true
    end
  end
end
