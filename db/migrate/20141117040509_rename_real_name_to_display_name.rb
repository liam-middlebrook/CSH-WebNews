class RenameRealNameToDisplayName < ActiveRecord::Migration
  def change
    rename_column :users, :real_name, :display_name
  end
end
