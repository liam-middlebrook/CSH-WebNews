class MoveFollowupToPosts < ActiveRecord::Migration
  def change
    remove_column :postings, :followup, :boolean
    add_reference :posts, :followup_newsgroup
  end
end
