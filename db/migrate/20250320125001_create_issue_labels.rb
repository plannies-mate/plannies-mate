# frozen_string_literal: true

# Create GitHub Labels
class CreateIssueLabels < ActiveRecord::Migration[8.0]
  def change
    create_table :issue_labels do |t|
      t.string :name, null: false
      t.string :color
      t.boolean :default, default: false
      t.string :description

      t.timestamps
    end

    add_index :issue_labels, :name, unique: true
  end
end
