class RenameStarredPostEntriesToStars < ActiveRecord::Migration
  def change
    rename_table :starred_post_entries, :stars
  end
end
