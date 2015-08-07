class AddMissingForeignKeys < ActiveRecord::Migration
  def change
    add_foreign_key :posts, :users, column: :sticky_user_id, on_delete: :nullify
    add_foreign_key :stars, :users, on_delete: :cascade
    add_foreign_key :subscriptions, :users, on_delete: :cascade
    add_foreign_key :unread_post_entries, :users, on_delete: :cascade
  end
end
