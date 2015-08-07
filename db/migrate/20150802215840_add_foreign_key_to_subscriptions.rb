class AddForeignKeyToSubscriptions < ActiveRecord::Migration
  def change
    rename_column :subscriptions, :newsgroup_name, :newsgroup_id
    add_foreign_key :subscriptions, :newsgroups
  end
end
