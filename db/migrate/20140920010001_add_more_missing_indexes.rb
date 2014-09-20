class AddMoreMissingIndexes < ActiveRecord::Migration
  def change
    add_index :posts, :sticky_user_id
    add_index :posts, :followup_newsgroup_id
    remove_index :newsgroups, column: :name
    add_index :newsgroups, :name, unique: true
    remove_index :posts, column: :message_id
    add_index :posts, :message_id, unique: true
    add_index :postings, [:newsgroup_id, :post_id], unique: true
    add_index :subscriptions, [:newsgroup_name, :user_id], unique: true
    remove_index :users, column: :username
    add_index :users, :username, unique: true
  end
end
