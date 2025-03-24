# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_03_24_175000) do
  create_table "authorities", force: :cascade do |t|
    t.string "short_name", null: false
    t.string "state"
    t.string "name", null: false
    t.string "url", null: false
    t.string "website_url"
    t.string "query_domain"
    t.string "admin_url"
    t.boolean "possibly_broken", default: false, null: false
    t.integer "population"
    t.date "last_received"
    t.integer "week_count", default: 0, null: false
    t.integer "month_count", default: 0, null: false
    t.integer "total_count", default: 0, null: false
    t.date "added_on"
    t.integer "median_per_week", default: 0, null: false
    t.integer "scraper_id", null: false
    t.text "last_log"
    t.integer "import_count", default: 0, null: false
    t.string "imported_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scraper_id"], name: "index_authorities_on_scraper_id"
    t.index ["short_name"], name: "index_authorities_on_short_name", unique: true
  end

  create_table "authorities_pull_requests", id: false, force: :cascade do |t|
    t.integer "authority_id", null: false
    t.integer "pull_request_id", null: false
    t.index ["authority_id", "pull_request_id"], name: "index_authorities_prs_on_authority_id_and_pr_id", unique: true
    t.index ["authority_id"], name: "index_authorities_pull_requests_on_authority_id"
    t.index ["pull_request_id"], name: "index_authorities_pull_requests_on_pull_request_id"
  end

  create_table "coverage_histories", force: :cascade do |t|
    t.date "recorded_on", null: false
    t.integer "authority_count", default: 0, null: false
    t.integer "broken_authority_count", default: 0, null: false
    t.integer "total_population", default: 0, null: false
    t.integer "broken_population", default: 0, null: false
    t.integer "pr_count", default: 0, null: false
    t.integer "pr_population", default: 0, null: false
    t.integer "fixed_count", default: 0, null: false
    t.integer "fixed_population", default: 0, null: false
    t.integer "rejected_count", default: 0, null: false
    t.integer "rejected_population", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recorded_on"], name: "index_coverage_histories_on_recorded_on", unique: true
  end

  create_table "github_users", force: :cascade do |t|
    t.string "login", null: false
    t.string "avatar_url"
    t.string "html_url"
    t.string "user_view_type"
    t.boolean "site_admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["login"], name: "index_github_users_on_login", unique: true
  end

  create_table "github_users_issues", id: false, force: :cascade do |t|
    t.integer "github_user_id", null: false
    t.integer "issue_id", null: false
    t.index ["github_user_id", "issue_id"], name: "index_github_users_issues_on_github_user_id_and_issue_id", unique: true
    t.index ["issue_id"], name: "index_github_users_issues_on_issue_id"
  end

  create_table "http_cache_entries", force: :cascade do |t|
    t.string "url", null: false
    t.string "etag"
    t.datetime "last_modified"
    t.datetime "last_success_at"
    t.datetime "last_other_response_at"
    t.datetime "last_not_modified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_http_cache_entries_on_url", unique: true
  end

  create_table "issue_labels", force: :cascade do |t|
    t.string "name", null: false
    t.string "color"
    t.boolean "default", default: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_issue_labels_on_name", unique: true
  end

  create_table "issue_labels_issues", id: false, force: :cascade do |t|
    t.integer "issue_label_id", null: false
    t.integer "issue_id", null: false
    t.index ["issue_id"], name: "index_issue_labels_issues_on_issue_id"
    t.index ["issue_label_id", "issue_id"], name: "index_issue_labels_issues_on_issue_label_id_and_issue_id", unique: true
  end

  create_table "issues", force: :cascade do |t|
    t.string "html_url"
    t.string "title"
    t.string "state"
    t.boolean "locked", default: false
    t.string "milestone"
    t.datetime "closed_at"
    t.integer "user_id"
    t.integer "assignee_id"
    t.integer "authority_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_issues_on_assignee_id"
    t.index ["authority_id"], name: "index_issues_on_authority_id"
    t.index ["user_id"], name: "index_issues_on_user_id"
  end

  create_table "pull_requests", force: :cascade do |t|
    t.string "url", null: false
    t.string "title"
    t.integer "scraper_id"
    t.integer "pr_number"
    t.string "github_owner"
    t.string "github_repo"
    t.date "closed_at_date"
    t.boolean "accepted", default: false
    t.datetime "last_checked_at"
    t.boolean "needs_github_update", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scraper_id"], name: "index_pull_requests_on_scraper_id"
    t.index ["url"], name: "index_pull_requests_on_url", unique: true
  end

  create_table "scrapers", force: :cascade do |t|
    t.string "morph_url", null: false
    t.string "github_url", null: false
    t.string "scraper_file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["morph_url"], name: "index_scrapers_on_morph_url", unique: true
  end

  add_foreign_key "authorities", "scrapers"
  add_foreign_key "authorities_pull_requests", "authorities"
  add_foreign_key "authorities_pull_requests", "pull_requests"
  add_foreign_key "github_users_issues", "github_users"
  add_foreign_key "github_users_issues", "issues"
  add_foreign_key "issue_labels_issues", "issue_labels"
  add_foreign_key "issue_labels_issues", "issues"
  add_foreign_key "issues", "authorities"
  add_foreign_key "issues", "github_users", column: "assignee_id"
  add_foreign_key "issues", "github_users", column: "user_id"
end
