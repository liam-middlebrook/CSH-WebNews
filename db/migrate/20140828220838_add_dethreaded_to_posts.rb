class AddDethreadedToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :dethreaded, :boolean, after: :stripped
  end
end
