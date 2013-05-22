class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :user
      t.string :newsgroup_name
      t.integer :unread_level
      t.integer :email_level
      t.string :email_type
      t.timestamps
    end
    
    add_index :subscriptions, :user_id
    add_index :subscriptions, :newsgroup_name
    
    User.find_each do |user|
      user.ensure_subscriptions
      if user.preferences[:unread_in_test] == '1'
        user.subscriptions.find_by_newsgroup_name('csh.test').destroy
      end
      if user.preferences[:unread_in_control] == '1'
        user.subscriptions.find_by_newsgroup_name('control.cancel').destroy
      end
    end
  end
end
