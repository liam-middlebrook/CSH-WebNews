class AddAuthorColumnsToPosts < ActiveRecord::Migration
  def change
    rename_column :posts, :author, :author_raw
    add_column :posts, :author_email, :text
    add_column :posts, :author_name, :text
  end
end
