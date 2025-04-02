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

ActiveRecord::Schema[8.0].define(version: 2025_03_30_011742) do
  create_table "authorities", force: :cascade do |t|
    t.string "short_name", null: false
    t.string "state"
    t.string "name", null: false
    t.boolean "possibly_broken", default: false, null: false
    t.integer "population"
    t.date "removed_on"
    t.date "last_received"
    t.integer "week_count", default: 0, null: false
    t.integer "month_count", default: 0, null: false
    t.integer "total_count", default: 0, null: false
    t.date "added_on"
    t.integer "median_per_week", default: 0, null: false
    t.integer "scraper_id"
    t.text "last_log"
    t.integer "import_count", default: 0, null: false
    t.string "imported_on"
    t.string "website_url"
    t.string "admin_url"
    t.string "query_domains"
    t.string "ip_addresses"
    t.string "whois_names"
    t.boolean "needs_import", default: true, null: false
    t.boolean "needs_generate", default: true, null: false
    t.datetime "import_triggered_at"
    t.string "import_trigger_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scraper_id"], name: "index_authorities_on_scraper_id"
    t.index ["short_name"], name: "index_authorities_on_short_name", unique: true
  end

  create_table "authorities_pull_requests", id: false, force: :cascade do |t|
    t.integer "authority_id", null: false
    t.integer "pull_request_id", null: false
    t.index ["authority_id", "pull_request_id"], name: "index_authorities_prs_on_authority_id_and_pr_id", unique: true
    t.index ["pull_request_id"], name: "index_authorities_pull_requests_on_pull_request_id"
  end

  create_table "coverage_histories", force: :cascade do |t|
    t.date "recorded_on", null: false
    t.string "wayback_url"
    t.integer "authority_count", default: 0, null: false
    t.integer "broken_authority_count", default: 0, null: false
    t.text "extra_broken_authorities", default: "[]", null: false
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
    t.index ["wayback_url"], name: "index_coverage_histories_on_wayback_url", unique: true
  end

  create_table "coverage_histories_authorities", id: false, force: :cascade do |t|
    t.integer "coverage_history_id", null: false
    t.integer "authority_id", null: false
    t.index ["authority_id"], name: "index_coverage_histories_authorities_on_authority_id"
    t.index ["coverage_history_id", "authority_id"], name: "idx_coverage_history_authorities", unique: true
  end

  create_table "github_users", force: :cascade do |t|
    t.string "login", null: false
    t.string "avatar_url"
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

  create_table "interesting_branches", force: :cascade do |t|
    t.integer "scraper_id", null: false
    t.string "branch_name", null: false
    t.datetime "last_commit_at", null: false
    t.string "last_commit_sha"
    t.integer "pull_request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "\"html_url\", \"branch_name\"", name: "index_interesting_branches_on_html_url_and_branch", unique: true
    t.index ["pull_request_id"], name: "index_interesting_branches_on_pull_request_id"
    t.index ["scraper_id"], name: "index_interesting_branches_on_scraper_id"
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
    t.integer "number", null: false
    t.string "title", null: false
    t.string "state", null: false
    t.boolean "locked", default: false, null: false
    t.datetime "closed_at"
    t.boolean "needs_import", default: true, null: false
    t.boolean "needs_generate", default: true, null: false
    t.datetime "import_triggered_at"
    t.string "import_trigger_reason"
    t.integer "authority_id"
    t.integer "scraper_id"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authority_id"], name: "index_issues_on_authority_id"
    t.index ["number"], name: "index_issues_on_number", unique: true
    t.index ["scraper_id"], name: "index_issues_on_scraper_id"
    t.index ["user_id"], name: "index_issues_on_user_id"
  end

  create_table "pull_requests", force: :cascade do |t|
    t.integer "scraper_id", null: false
    t.integer "number", null: false
    t.string "title", null: false
    t.string "state", null: false
    t.boolean "locked", default: false, null: false
    t.string "head_branch_name", null: false
    t.string "base_branch_name", null: false
    t.datetime "closed_at"
    t.datetime "merged_at"
    t.string "merge_commit_sha"
    t.boolean "needs_import", default: false, null: false
    t.datetime "import_triggered_at"
    t.string "import_trigger_reason"
    t.integer "issue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_pull_requests_on_issue_id"
    t.index ["number"], name: "index_pull_requests_on_number", unique: true
    t.index ["scraper_id", "number"], name: "index_pull_requests_on_scraper_id_and_number", unique: true
    t.index ["scraper_id"], name: "index_pull_requests_on_scraper_id"
  end

  create_table "scrapers", force: :cascade do |t|
    t.string "name", null: false
    t.string "default_branch", default: "master", null: false
    t.string "scraper_path"
    t.string "authorities_path"
    t.boolean "needs_import", default: true, null: false
    t.boolean "needs_generate", default: true, null: false
    t.datetime "update_requested_at"
    t.string "update_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_scrapers_on_name", unique: true
  end

  add_foreign_key "authorities", "scrapers"
  add_foreign_key "authorities_pull_requests", "authorities"
  add_foreign_key "authorities_pull_requests", "pull_requests"
  add_foreign_key "coverage_histories_authorities", "authorities"
  add_foreign_key "coverage_histories_authorities", "coverage_histories"
  add_foreign_key "github_users_issues", "github_users"
  add_foreign_key "github_users_issues", "issues"
  add_foreign_key "interesting_branches", "pull_requests"
  add_foreign_key "interesting_branches", "scrapers"
  add_foreign_key "issue_labels_issues", "issue_labels"
  add_foreign_key "issue_labels_issues", "issues"
  add_foreign_key "issues", "authorities"
  add_foreign_key "issues", "github_users", column: "user_id"
  add_foreign_key "issues", "scrapers"
  add_foreign_key "pull_requests", "issues"
  add_foreign_key "pull_requests", "scrapers"
end
