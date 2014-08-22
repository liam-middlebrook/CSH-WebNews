class EmbiggenStringColumns < ActiveRecord::Migration
  def up
    change_column :newsgroups, :name, :text
    change_column :newsgroups, :status, :text
    change_column :posts, :newsgroup_name, :text
    change_column :posts, :subject, :text
    change_column :posts, :author, :text
    change_column :posts, :message_id, :text
    change_column :posts, :parent_id, :text
    change_column :posts, :thread_id, :text
    change_column :subscriptions, :newsgroup_name, :text
    change_column :subscriptions, :digest_type, :text
    change_column :users, :username, :text
    change_column :users, :real_name, :text
    change_column :users, :api_key, :text
  end

  def down
    change_column :newsgroups, :name, :string
    change_column :newsgroups, :status, :string
    change_column :posts, :newsgroup_name, :string
    change_column :posts, :subject, :string
    change_column :posts, :author, :string
    change_column :posts, :message_id, :string
    change_column :posts, :parent_id, :string
    change_column :posts, :thread_id, :string
    change_column :subscriptions, :newsgroup_name, :string
    change_column :subscriptions, :digest_type, :string
    change_column :users, :username, :string
    change_column :users, :real_name, :string
    change_column :users, :api_key, :string
  end
end
