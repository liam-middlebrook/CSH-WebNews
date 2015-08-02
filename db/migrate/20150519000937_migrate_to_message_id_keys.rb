class MigrateToMessageIdKeys < ActiveRecord::Migration
  def up
    execute 'DROP SEQUENCE posts_id_seq CASCADE'
    change_column :posts, :id, :text
    change_column :postings, :post_id, :text
    change_column :stars, :post_id, :text
    change_column :unread_post_entries, :post_id, :text
    add_foreign_key :postings, :posts, on_update: :cascade, on_delete: :cascade
    add_foreign_key :stars, :posts, on_update: :cascade, on_delete: :cascade
    add_foreign_key :unread_post_entries, :posts, on_update: :cascade, on_delete: :cascade
    #### Uncomment to make reversible
    # add_column :posts, :old_id, :text
    # execute 'UPDATE posts SET old_id = id'
    execute 'UPDATE posts SET id = message_id'
    remove_column :posts, :message_id
    Post.update_all(ancestry: '')

    say 'WARNING: All ancestries deleted!'
  end

  def down
    raise ActiveRecord::IrreversibleMigration

    add_column :posts, :message_id, :text
    execute 'UPDATE posts SET message_id = id'
    #### Uncomment to make reversible
    # execute 'UPDATE posts SET id = old_id'
    # remove_column :posts, :old_id
    remove_foreign_key :unread_post_entries, :posts
    remove_foreign_key :stars, :posts
    remove_foreign_key :postings, :posts
    execute 'ALTER TABLE unread_post_entries ALTER COLUMN post_id TYPE integer USING (post_id::integer)'
    execute 'ALTER TABLE stars ALTER COLUMN post_id TYPE integer USING (post_id::integer)'
    execute 'ALTER TABLE postings ALTER COLUMN post_id TYPE integer USING (post_id::integer)'
    execute 'ALTER TABLE posts ALTER COLUMN id TYPE integer USING (id::integer)'
    execute 'CREATE SEQUENCE posts_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1'
    execute 'ALTER SEQUENCE posts_id_seq OWNED BY posts.id'
    execute "ALTER TABLE ONLY posts ALTER COLUMN id SET DEFAULT nextval('posts_id_seq'::regclass)"

    say 'WARNING: Ancestries not restored!'
  end
end
