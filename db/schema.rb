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

ActiveRecord::Schema[7.2].define(version: 2026_09_02_211945) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "icon"
    t.string "color"
    t.uuid "user_id"
    t.boolean "is_preset", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "exchange_rates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "rate_date", null: false
    t.string "from_currency", null: false
    t.string "to_currency", null: false
    t.decimal "rate", precision: 12, scale: 6, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rate_date", "from_currency", "to_currency"], name: "index_exchange_rates_on_date_and_currencies", unique: true
  end

  create_table "history_log_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id", null: false
    t.string "period", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "currency", null: false
    t.boolean "is_estimated", default: false, null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id", "period"], name: "index_history_log_entries_on_subscription_id_and_period", unique: true
    t.index ["subscription_id"], name: "index_history_log_entries_on_subscription_id"
  end

  create_table "household_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "household_id", null: false
    t.uuid "user_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "joined_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id"], name: "index_household_members_on_household_id"
    t.index ["user_id"], name: "index_household_members_on_user_id", unique: true
  end

  create_table "households", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_households_on_owner_id"
  end

  create_table "one_time_expenses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "category_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "currency", null: false
    t.date "expense_date", null: false
    t.text "note"
    t.uuid "household_id"
    t.string "visibility", default: "shared", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_one_time_expenses_on_category_id"
    t.index ["household_id"], name: "index_one_time_expenses_on_household_id"
    t.index ["user_id"], name: "index_one_time_expenses_on_user_id"
  end

  create_table "passwordless_login_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "token_hash", null: false
    t.string "code_hash", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_passwordless_login_requests_on_email"
    t.index ["token_hash"], name: "index_passwordless_login_requests_on_token_hash", unique: true
  end

  create_table "reminder_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id", null: false
    t.string "channel", null: false
    t.string "trigger_reason", null: false
    t.datetime "sent_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id"], name: "index_reminder_logs_on_subscription_id"
  end

  create_table "service_directory_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "icon_asset", null: false
    t.string "brand_color"
    t.string "cancellation_url"
    t.string "region", default: "global", null: false
    t.uuid "default_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["default_category_id"], name: "index_service_directory_entries_on_default_category_id"
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "service_directory_entry_id"
    t.uuid "category_id", null: false
    t.string "name", null: false
    t.string "currency", null: false
    t.string "billing_cycle", null: false
    t.string "amount_type", null: false
    t.string "subscription_type", default: "regular", null: false
    t.string "status", default: "active", null: false
    t.date "billing_anchor_date", null: false
    t.date "trial_end_date"
    t.integer "rating"
    t.string "tag"
    t.string "icon_override"
    t.string "color_override"
    t.text "notes"
    t.integer "custom_reminder_lead_days"
    t.uuid "household_id"
    t.string "visibility", default: "shared", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_subscriptions_on_category_id"
    t.index ["household_id"], name: "index_subscriptions_on_household_id"
    t.index ["service_directory_entry_id"], name: "index_subscriptions_on_service_directory_entry_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "home_currency", default: "EUR", null: false
    t.integer "default_reminder_lead_days", default: 3, null: false
    t.boolean "is_premium", default: false, null: false
    t.datetime "premium_since"
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "categories", "users"
  add_foreign_key "history_log_entries", "subscriptions"
  add_foreign_key "household_members", "households"
  add_foreign_key "household_members", "users"
  add_foreign_key "households", "users", column: "owner_id"
  add_foreign_key "one_time_expenses", "categories"
  add_foreign_key "one_time_expenses", "households"
  add_foreign_key "one_time_expenses", "users"
  add_foreign_key "reminder_logs", "subscriptions"
  add_foreign_key "service_directory_entries", "categories", column: "default_category_id"
  add_foreign_key "subscriptions", "categories"
  add_foreign_key "subscriptions", "households"
  add_foreign_key "subscriptions", "service_directory_entries"
  add_foreign_key "subscriptions", "users"
end
