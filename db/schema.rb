# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140916160844) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "flags", force: true do |t|
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "newsgroups", force: true do |t|
    t.text     "name"
    t.text     "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "newsgroups", ["name"], name: "index_newsgroups_on_name", using: :btree

  create_table "postings", force: true do |t|
    t.integer "newsgroup_id"
    t.integer "post_id"
    t.integer "number"
    t.boolean "top_level"
  end

  add_index "postings", ["newsgroup_id"], name: "index_postings_on_newsgroup_id", using: :btree
  add_index "postings", ["post_id"], name: "index_postings_on_post_id", using: :btree

  create_table "posts", force: true do |t|
    t.text     "subject"
    t.text     "author"
    t.datetime "date"
    t.text     "message_id"
    t.boolean  "stripped"
    t.integer  "sticky_user_id"
    t.datetime "sticky_until"
    t.text     "headers"
    t.text     "body"
    t.boolean  "dethreaded"
    t.integer  "followup_newsgroup_id"
    t.text     "ancestry"
  end

  add_index "posts", ["ancestry"], name: "index_posts_on_ancestry", using: :btree
  add_index "posts", ["date"], name: "index_posts_on_date", using: :btree
  add_index "posts", ["message_id"], name: "index_posts_on_message_id", using: :btree
  add_index "posts", ["sticky_until"], name: "index_posts_on_sticky_until", using: :btree

  create_table "starred_post_entries", force: true do |t|
    t.integer  "user_id"
    t.integer  "post_id"
    t.datetime "created_at"
  end

  add_index "starred_post_entries", ["post_id"], name: "index_starred_post_entries_on_post_id", using: :btree
  add_index "starred_post_entries", ["user_id", "post_id"], name: "index_starred_post_entries_on_user_id_and_post_id", unique: true, using: :btree
  add_index "starred_post_entries", ["user_id"], name: "index_starred_post_entries_on_user_id", using: :btree

  create_table "subscriptions", force: true do |t|
    t.integer  "user_id"
    t.text     "newsgroup_name"
    t.integer  "unread_level"
    t.integer  "email_level"
    t.text     "digest_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["newsgroup_name"], name: "index_subscriptions_on_newsgroup_name", using: :btree
  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "unread_post_entries", force: true do |t|
    t.integer "user_id"
    t.integer "post_id"
    t.integer "personal_level"
    t.boolean "user_created"
  end

  add_index "unread_post_entries", ["post_id"], name: "index_unread_post_entries_on_post_id", using: :btree
  add_index "unread_post_entries", ["user_id", "post_id"], name: "index_unread_post_entries_on_user_id_and_post_id", unique: true, using: :btree
  add_index "unread_post_entries", ["user_id"], name: "index_unread_post_entries_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.text     "username"
    t.text     "real_name"
    t.text     "preferences"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "api_key"
    t.text     "api_data"
  end

  add_index "users", ["api_key"], name: "index_users_on_api_key", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

end
