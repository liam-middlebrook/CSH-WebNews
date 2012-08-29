class AddApiAttributesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :api_key, :string
    add_column :users, :api_last_access, :datetime
    add_column :users, :api_last_agent, :string
    add_index :users, :api_key
  end
end
