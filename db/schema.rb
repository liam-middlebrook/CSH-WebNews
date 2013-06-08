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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130608141604) do

  create_table "newsgroups", :force => true do |t|
    t.string "name"
    t.string "status"
  end

  create_table "posts", :force => true do |t|
    t.string   "newsgroup_name"
    t.integer  "number"
    t.string   "subject"
    t.string   "author"
    t.datetime "date"
    t.string   "message_id"
    t.string   "parent_id"
    t.text     "headers"
    t.text     "body"
    t.string   "thread_id"
    t.boolean  "stripped"
    t.integer  "sticky_user_id"
    t.datetime "sticky_until"
  end

  add_index "posts", ["date"], :name => "index_posts_on_date"
  add_index "posts", ["message_id"], :name => "index_posts_on_message_id"
  add_index "posts", ["newsgroup_name", "number"], :name => "index_posts_on_newsgroup_name_and_number", :unique => true
  add_index "posts", ["parent_id"], :name => "index_posts_on_parent_id"
  add_index "posts", ["sticky_until"], :name => "index_posts_on_sticky_until"
  add_index "posts", ["thread_id"], :name => "index_posts_on_thread_id"

  create_table "starred_post_entries", :force => true do |t|
    t.integer "user_id"
    t.integer "post_id"
  end

  add_index "starred_post_entries", ["user_id", "post_id"], :name => "index_starred_post_entries_on_user_id_and_post_id", :unique => true

  create_table "subscriptions", :force => true do |t|
    t.integer  "user_id"
    t.string   "newsgroup_name"
    t.integer  "unread_level"
    t.integer  "email_level"
    t.string   "digest_type"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "subscriptions", ["newsgroup_name"], :name => "index_subscriptions_on_newsgroup_name"
  add_index "subscriptions", ["user_id"], :name => "index_subscriptions_on_user_id"

  create_table "unread_post_entries", :force => true do |t|
    t.integer "user_id"
    t.integer "newsgroup_id"
    t.integer "post_id"
    t.integer "personal_level"
    t.boolean "user_created"
  end

  add_index "unread_post_entries", ["user_id", "post_id"], :name => "index_unread_post_entries_on_user_id_and_post_id", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "real_name"
    t.text     "preferences"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_key"
    t.text     "api_data"
  end

  add_index "users", ["api_key"], :name => "index_users_on_api_key"

end
