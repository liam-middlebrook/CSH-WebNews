class MigrateToAncestry < ActiveRecord::Migration
  def up
    change_table :posts do |t|
      t.remove :parent_id
      t.remove :thread_id
      t.text :ancestry
      t.index :ancestry
    end

    say 'WARNING: Threading data must be manually reconstructed!'
  end

  def down
    change_table :posts do |t|
      t.remove :ancestry
      t.text :parent_id
      t.text :thread_id
      t.index :parent_id
      t.index :thread_id
    end

    say 'WARNING: Threading data not restored!'
  end
end
