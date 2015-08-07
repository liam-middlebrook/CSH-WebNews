class ChangeForeignKeyCascades < ActiveRecord::Migration
  def up
    remove_foreign_key :posts, column: :followup_newsgroup_id
    add_foreign_key :posts, :newsgroups, column: :followup_newsgroup_id, on_update: :cascade, on_delete: :nullify
  end

  def down
    remove_foreign_key :posts, column: :followup_newsgroup_id
    add_foreign_key :posts, :newsgroups, column: :followup_newsgroup_id, on_update: :cascade, on_delete: :cascade
  end
end
