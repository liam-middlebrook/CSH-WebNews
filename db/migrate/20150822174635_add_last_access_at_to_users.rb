class AddLastAccessAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_access_at, :datetime

    reversible do |dir|
      dir.up { User.update_all('last_access_at = updated_at') }
    end
  end
end
