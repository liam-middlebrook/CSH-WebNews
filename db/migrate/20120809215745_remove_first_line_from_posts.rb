class RemoveFirstLineFromPosts < ActiveRecord::Migration
  def change
    remove_column :posts, :first_line
  end
end
