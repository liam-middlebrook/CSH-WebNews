class AddUserCreatedToUnreadPostEntries < ActiveRecord::Migration
  def change
    add_column :unread_post_entries, :user_created, :boolean
  end
end
