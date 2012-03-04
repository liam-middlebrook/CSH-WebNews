class AddStickyAttributesToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :sticky_user_id, :integer, :after => :stripped
    add_column :posts, :sticky_until, :datetime, :after => :sticky_user_id
    add_index :posts, :sticky_until
  end
end
