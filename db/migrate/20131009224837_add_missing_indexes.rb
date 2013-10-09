class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :newsgroups, :name
    add_index :posts, :newsgroup_name
    add_index :users, :username
    add_index :starred_post_entries, :user_id
    add_index :starred_post_entries, :post_id
    add_index :unread_post_entries, :user_id
    add_index :unread_post_entries, :newsgroup_id
    add_index :unread_post_entries, :post_id
  end
end
