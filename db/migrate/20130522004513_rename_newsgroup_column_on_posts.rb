class RenameNewsgroupColumnOnPosts < ActiveRecord::Migration
  def change
    rename_column :posts, :newsgroup, :newsgroup_name
    rename_index :posts, 'index_posts_on_newsgroup_and_number', 'index_posts_on_newsgroup_name_and_number'
  end
end
