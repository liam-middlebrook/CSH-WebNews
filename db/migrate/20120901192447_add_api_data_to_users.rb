class AddApiDataToUsers < ActiveRecord::Migration
  def change
    remove_column :users, :api_last_access
    remove_column :users, :api_last_agent
    add_column :users, :api_data, :text
  end
end
