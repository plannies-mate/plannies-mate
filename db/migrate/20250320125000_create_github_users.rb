# frozen_string_literal: true

# Create GitHub Users
class CreateGithubUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :github_users do |t|
      t.string :login, null: false
      t.string :avatar_url
      t.string :html_url
      t.string :user_view_type
      t.boolean :site_admin, default: false

      t.timestamps
    end

    add_index :github_users, :login, unique: true
  end
end
