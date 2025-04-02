# frozen_string_literal: true

# Create GitHub Users
class CreateGithubUsers < ActiveRecord::Migration[8.0]
  def change
    # Updated as encountered, deleted when no longer referenced for 30 days
    create_table :github_users do |t|
      t.string :login, null: false, index: { unique: true }
      t.string :avatar_url
      t.string :user_view_type
      t.boolean :site_admin, default: false

      t.timestamps null: false
    end
  end
end
