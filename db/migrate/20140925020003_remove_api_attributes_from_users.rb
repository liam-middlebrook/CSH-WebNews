class RemoveAPIAttributesFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :api_key, :text, index: true
    remove_column :users, :api_data, :text
  end
end
