class FixAncestryIndex < ActiveRecord::Migration
  def up
    remove_index :posts, :ancestry
    execute "CREATE INDEX index_posts_on_ancestry ON posts USING btree (ancestry text_pattern_ops)"
  end

  def down
    remove_index :posts, :ancestry
    add_index :posts, :ancestry
  end
end
