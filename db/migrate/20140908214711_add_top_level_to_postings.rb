class AddTopLevelToPostings < ActiveRecord::Migration
  def change
    add_column :postings, :top_level, :boolean
  end
end
