class FixMissingTimestamps < ActiveRecord::Migration
  def change
    add_column :newsgroups, :created_at, :datetime
    add_column :newsgroups, :updated_at, :datetime
    add_column :starred_post_entries, :created_at, :datetime
    change_column_null :subscriptions, :created_at, true
    change_column_null :subscriptions, :updated_at, true
  end
end
