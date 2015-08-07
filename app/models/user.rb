# == Schema Information
#
# Table name: users
#
#  id           :integer          not null, primary key
#  username     :text
#  display_name :text
#  preferences  :text
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_users_on_username  (username) UNIQUE
#

class User < ActiveRecord::Base
  has_many :unread_post_entries, dependent: :destroy
  has_many :stars, dependent: :destroy
  has_many :unread_posts, through: :unread_post_entries, source: :post
  has_many :starred_posts, through: :stars, source: :post
  has_many :subscriptions, autosave: true, dependent: :destroy
  has_one :default_subscription, -> { where(newsgroup_id: nil) }, class_name: Subscription
  has_many :oauth_applications, class_name: Doorkeeper::Application, as: :owner

  validates! :username, :display_name, presence: true
  validates! :username, uniqueness: true

  after_create :ensure_subscriptions

  serialize :preferences, Hash

  def self.active
    where('updated_at >= ?', 3.months.ago)
  end

  def self.inactive
    where('updated_at < ?', 3.months.ago)
  end

  def inactive?
    updated_at < 3.months.ago
  end

  def admin?
    unix_groups.include?('rtp') || unix_groups.include?('eboard')
  end

  def email
    "#{username}@#{LOCAL_DOMAIN}"
  end

  def time_zone
    preferences[:time_zone] || DEFAULT_TIME_ZONE
  end

  private

  def ensure_subscriptions
    if subscriptions.none?
      NEW_USER_SUBSCRIPTIONS.each do |attrs|
        Subscription.create!(attrs.merge(user: self))
      end
    end
  end

  def unix_groups
    @unix_groups ||= `groups #{username}`.split.reject{ |g| g == username } rescue []
  end
end
