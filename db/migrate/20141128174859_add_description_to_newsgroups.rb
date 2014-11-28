class AddDescriptionToNewsgroups < ActiveRecord::Migration
  def change
    add_column :newsgroups, :description, :text
  end
end
