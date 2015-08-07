class RenameUnreadPostEntriesToUnreads < ActiveRecord::Migration
  def change
    rename_table :unread_post_entries, :unreads
  end
end
