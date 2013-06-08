class MigrateEmailTypeToDigestType < ActiveRecord::Migration
  def up
    rename_column :subscriptions, :email_type, :digest_type
    Subscription.where(newsgroup_name: nil, digest_type: 'immediate').update_all(digest_type: 'none')
    Subscription.where(newsgroup_name: 'control.cancel', digest_type: nil).update_all(digest_type: 'none')
    Subscription.where(newsgroup_name: 'csh.test', digest_type: nil).update_all(digest_type: 'none')
    Subscription.where(digest_type: 'immediate').update_all(digest_type: nil)
    Subscription.where(digest_type: 'daily_digest').update_all(digest_type: 'daily')
    Subscription.where(digest_type: 'weekly_digest').update_all(digest_type: 'weekly')
    Subscription.where(digest_type: 'monthly_digest').update_all(digest_type: 'monthly')
  end

  def down
    Subscription.where(digest_type: 'daily').update_all(digest_type: 'daily_digest')
    Subscription.where(digest_type: 'weekly').update_all(digest_type: 'weekly_digest')
    Subscription.where(digest_type: 'monthly').update_all(digest_type: 'monthly_digest')
    rename_column :subscriptions, :digest_type, :email_type
  end
end
