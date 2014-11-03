class RenameMiscPostColumns < ActiveRecord::Migration
  def change
    rename_column :posts, :date, :created_at
    rename_column :posts, :dethreaded, :is_dethreaded
    rename_column :posts, :stripped, :had_attachments
    rename_column :posts, :sticky_until, :sticky_expires_at
  end
end
