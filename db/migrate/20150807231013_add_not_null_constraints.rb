class AddNotNullConstraints < ActiveRecord::Migration
  def change
    change_column_null :posts, :subject, false
    change_column_null :posts, :headers, false
    change_column_null :posts, :author_raw, false
    change_column_null :posts, :had_attachments, false
    change_column_null :posts, :is_dethreaded, false
    change_column_null :postings, :newsgroup_id, false
    change_column_null :postings, :post_id, false
    change_column_null :postings, :number, false
    change_column_null :postings, :top_level, false
    change_column_null :stars, :user_id, false
    change_column_null :stars, :post_id, false
    change_column_null :subscriptions, :user_id, false
    change_column_null :unread_post_entries, :user_id, false
    change_column_null :unread_post_entries, :post_id, false
    change_column_null :unread_post_entries, :personal_level, false
    change_column_null :users, :username, false
    change_column_null :users, :display_name, false
  end
end
