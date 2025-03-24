# frozen_string_literal: true

# Create join table for issues and assignees (many-to-many)
class CreateGithubUsersIssues < ActiveRecord::Migration[8.0]
  def change
    # Use Rails naming convention for HABTM join tables (alphabetical order of table names)
    create_table :github_users_issues, id: false do |t|
      t.references :github_user, null: false, foreign_key: true, index: false
      t.references :issue, null: false, foreign_key: true
    end

    add_index :github_users_issues, %i[github_user_id issue_id], unique: true
  end
end
