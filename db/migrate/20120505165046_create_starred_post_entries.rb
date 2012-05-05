class CreateStarredPostEntries < ActiveRecord::Migration
  def change
    create_table :starred_post_entries do |t|
      t.references :user
      t.references :post
    end
    add_index :starred_post_entries, [:user_id, :post_id], :unique => true
  end
end
