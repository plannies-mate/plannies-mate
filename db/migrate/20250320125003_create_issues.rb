# frozen_string_literal: true

# Create Issues
class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.integer :number, null: false
      t.string :html_url, null: false, index: { unique: true }
      t.string :title, null: false
      t.string :state, null: false
      t.boolean :locked, null: false, default: false
      t.datetime :closed_at

      # Relations
      t.references :authority, foreign_key: true, null: true
      t.references :user, foreign_key: { to_table: :github_users }, null: false
      t.references :scraper, foreign_key: true, null: false

      t.timestamps # Use standard Rails timestamps
    end

    # Use Rails naming convention for HABTM join tables (alphabetical order of table names)
    create_table :issue_labels_issues, id: false do |t|
      t.references :issue_label, null: false, foreign_key: true, index: false
      t.references :issue, null: false, foreign_key: true
    end

    add_index :issue_labels_issues, %i[issue_label_id issue_id], unique: true

    # Use Rails naming convention for HABTM join tables (alphabetical order of table names)
    create_table :github_users_issues, id: false do |t|
      t.references :github_user, null: false, foreign_key: true, index: false
      t.references :issue, null: false, foreign_key: true
    end

    add_index :github_users_issues, %i[github_user_id issue_id], unique: true
  end
end
