class AddPostAuthorIndexes < ActiveRecord::Migration
  def up
    execute "CREATE INDEX index_posts_on_author_raw ON posts USING btree (author_raw text_pattern_ops)"
    execute "CREATE INDEX index_posts_on_author_name ON posts USING btree (author_name text_pattern_ops)"
    execute "CREATE INDEX index_posts_on_author_email ON posts USING btree (author_email text_pattern_ops)"
  end

  def down
    remove_index :posts, :author_raw
    remove_index :posts, :author_name
    remove_index :posts, :author_email
  end
end
