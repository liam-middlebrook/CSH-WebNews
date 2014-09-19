class RemoveNewsgroupFromUnreadPostEntries < ActiveRecord::Migration
  def up
    remove_column :unread_post_entries, :newsgroup_id
  end

  def down
    add_reference :unread_post_entries, :newsgroup, index: true
  end
end
