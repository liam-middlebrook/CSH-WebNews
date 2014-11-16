class DefaultBooleansToFalse < ActiveRecord::Migration
  def up
    change_column_default :postings, :top_level, false
    change_column_default :posts, :had_attachments, false
    change_column_default :posts, :is_dethreaded, false
    change_column_default :unread_post_entries, :user_created, false
  end

  def down
    change_column_default :postings, :top_level, nil
    change_column_default :posts, :had_attachments, nil
    change_column_default :posts, :is_dethreaded, nil
    change_column_default :unread_post_entries, :user_created, nil
  end
end
