# == Schema Information
#
# Table name: users
#
#  id          :integer          not null, primary key
#  username    :text
#  real_name   :text
#  preferences :text
#  created_at  :datetime
#  updated_at  :datetime
#  api_key     :text
#  api_data    :text
#
# Indexes
#
#  index_users_on_api_key   (api_key)
#  index_users_on_username  (username) UNIQUE
#

class User < ActiveRecord::Base
  has_many :unread_post_entries, dependent: :destroy
  has_many :starred_post_entries, dependent: :destroy
  has_many :unread_posts, through: :unread_post_entries, source: :post
  has_many :starred_posts, through: :starred_post_entries, source: :post
  has_one :default_subscription, -> { where(newsgroup_name: nil) },
    class_name: Subscription, autosave: true, dependent: :destroy
  has_many :subscriptions, -> { where.not(newsgroup_name: nil) },
    autosave: true, dependent: :destroy

  accepts_nested_attributes_for :default_subscription
  accepts_nested_attributes_for :subscriptions, allow_destroy: true, reject_if: :all_blank

  validates! :username, :real_name, presence: true
  validates! :username, :api_key, uniqueness: true

  before_save :ensure_subscriptions

  serialize :preferences, Hash
  serialize :api_data, Hash

  def self.active
    where('updated_at >= ?', 3.months.ago)
  end

  def self.inactive
    where('updated_at < ?', 3.months.ago)
  end

  def inactive?
    updated_at < 3.months.ago
  end

  def unix_groups
    @unix_groups ||= `groups #{username}`.split.reject{ |g| g == username } rescue []
  end

  def admin?
    DEVELOPMENT_MODE or unix_groups.include?('rtp') or unix_groups.include?('eboard')
  end

  def api_enabled?
    !api_key.nil?
  end

  def email
    "#{username}@#{LOCAL_DOMAIN}"
  end

  def theme
    preferences[:theme].try(:to_sym) || :classic
  end

  def time_zone
    preferences[:time_zone] || 'Eastern Time (US & Canada)'
  end

  def thread_mode
    preferences[:thread_mode].try(:to_sym) || :normal
  end

  def ensure_subscriptions
    if !default_subscription.present?
      subscriptions.destroy_all
      NEW_USER_SUBSCRIPTIONS.each do |attrs|
        subscriptions << Subscription.new(attrs)
      end
    end
  end

  def unread_count
    unread_post_entries.count
  end

  def unread_count_in_thread
    unread_post_entries.where(personal_level: PERSONAL_CODES[:mine_in_thread]).count
  end

  def unread_count_in_reply
    unread_post_entries.where(personal_level: PERSONAL_CODES[:mine_reply]).count
  end

  def self.clean_unread!
    inactive.each do |user|
      UnreadPostEntry.where(user_id: user.id).delete_all
    end
  end
end
