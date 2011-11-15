class AddStrippedToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :stripped, :boolean, :after => :thread_id
  end
end
