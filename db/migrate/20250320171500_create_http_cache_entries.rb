# frozen_string_literal: true

class CreateHttpCacheEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :http_cache_entries do |t|
      t.string :url, null: false, index: { unique: true }
      t.string :etag
      t.datetime :last_modified_at
      t.datetime :last_success_at
      t.datetime :last_other_response_at
      t.datetime :last_not_modified_at
      t.timestamps null: false
    end
  end
end
