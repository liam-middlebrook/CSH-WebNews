class User < ActiveRecord::Base
  has_many :unread_post_entries
  has_many :starred_post_entries
  has_many :unread_posts, :through => :unread_post_entries, :source => :post
  has_many :starred_posts, :through => :starred_post_entries, :source => :post
  
  serialize :preferences, Hash
  
  scope :active, where('updated_at >= ?', 3.months.ago)
  scope :inactive, where('updated_at < ?', 3.months.ago)
  
  def is_inactive?
    updated_at < 3.months.ago
  end
  
  def unix_groups
    @unix_groups ||= `groups #{username}`.split.reject{ |g| g == username } rescue []
  end
  
  def is_admin?
    unix_groups.include?('rtp') or unix_groups.include?('eboard')
  end
  
  def email
    username + LOCAL_EMAIL_DOMAIN
  end
  
  def time_zone
    preferences[:time_zone] || 'Eastern Time (US & Canada)'
  end
  
  def thread_mode
    preferences[:thread_mode].andand.to_sym || :normal
  end
  
  def unread_in_test?
    (preferences[:unread_in_test] == '1') || false
  end
  
  def unread_in_control?
    (preferences[:unread_in_control] == '1') || false
  end
  
  def unread_in_lists?
    (preferences[:unread_in_lists] == '1') || false
  end
  
  def unread_in_group?(newsgroup)
    return false if
      (newsgroup.name == 'csh.test' and not unread_in_test?) or
      (newsgroup.name[/^control/] and not unread_in_control?) or
      (newsgroup.name[/^csh.lists/] and not unread_in_lists?)
    return true
  end
  
  def unread_count
    unread_post_entries.count
  end
  
  def unread_count_in_thread
    unread_post_entries.where(:personal_level => PERSONAL_CODES[:mine_in_thread]).count
  end
  
  def unread_count_in_reply
    unread_post_entries.where(:personal_level => PERSONAL_CODES[:mine_reply]).count
  end
  
  def self.clean_unread!
    inactive.each do |user|
      UnreadPostEntry.where(:user_id => user.id).delete_all
    end
  end
end
