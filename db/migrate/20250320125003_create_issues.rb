# frozen_string_literal: true

# Create Issues
class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.string :html_url
      t.string :title
      t.string :state
      t.boolean :locked, default: false
      t.string :milestone
      t.datetime :closed_at

      # Relations
      t.references :user, foreign_key: { to_table: :github_users }
      t.references :assignee, foreign_key: { to_table: :github_users }, null: true
      t.references :authority, foreign_key: true, null: true

      t.timestamps # Use standard Rails timestamps
    end
  end
end
