class MigrateToNewsgroupNameKeys < ActiveRecord::Migration
    def up
    execute 'DROP SEQUENCE newsgroups_id_seq CASCADE'
    change_column :newsgroups, :id, :text
    change_column :postings, :newsgroup_id, :text
    change_column :posts, :followup_newsgroup_id, :text
    add_foreign_key :postings, :newsgroups, on_update: :cascade, on_delete: :cascade
    add_foreign_key :posts, :newsgroups, column: :followup_newsgroup_id, on_update: :cascade, on_delete: :cascade
    #### Uncomment to make reversible
    # add_column :newsgroups, :old_id, :text
    # execute 'UPDATE newsgroups SET old_id = id'
    execute 'UPDATE newsgroups SET id = name'
    remove_column :newsgroups, :name
  end

  def down
    raise ActiveRecord::IrreversibleMigration

    add_column :newsgroups, :name, :text
    execute 'UPDATE newsgroups SET name = id'
    #### Uncomment to make reversible
    # execute 'UPDATE newsgroups SET id = old_id'
    # remove_column :newsgroups, :old_id
    remove_foreign_key :postings, :newsgroups
    remove_foreign_key :posts, column: :followup_newsgroup_id
    execute 'ALTER TABLE posts ALTER COLUMN followup_newsgroup_id TYPE integer USING (followup_newsgroup_id::integer)'
    execute 'ALTER TABLE postings ALTER COLUMN newsgroup_id TYPE integer USING (newsgroup_id::integer)'
    execute 'ALTER TABLE newsgroups ALTER COLUMN id TYPE integer USING (id::integer)'
    execute 'CREATE SEQUENCE newsgroups_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1'
    execute 'ALTER SEQUENCE newsgroups_id_seq OWNED BY newsgroups.id'
    execute "ALTER TABLE ONLY newsgroups ALTER COLUMN id SET DEFAULT nextval('newsgroups_id_seq'::regclass)"
  end
end
