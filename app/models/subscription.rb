# == Schema Information
#
# Table name: subscriptions
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  newsgroup_name :text
#  unread_level   :integer
#  email_level    :integer
#  digest_type    :text
#  created_at     :datetime
#  updated_at     :datetime
#
# Indexes
#
#  index_subscriptions_on_newsgroup_name              (newsgroup_name)
#  index_subscriptions_on_newsgroup_name_and_user_id  (newsgroup_name,user_id) UNIQUE
#  index_subscriptions_on_user_id                     (user_id)
#

class Subscription < ActiveRecord::Base
  DIGEST_TYPES = %w(none daily weekly monthly)

  belongs_to :user
  belongs_to :newsgroup, foreign_key: :newsgroup_name, primary_key: :name

  validates :user, presence: true
  validates :newsgroup_name, uniqueness: { scope: :user_id, message: 'is duplicated' }
  validates :unread_level, :email_level, numericality: {
    greater_than_or_equal_to: 0, less_than: PERSONAL_LEVELS.length, allow_nil: true
  }
  validates :digest_type, inclusion: { in: DIGEST_TYPES, allow_blank: true }

  def self.for(newsgroups)
    where(newsgroup_name: Array(newsgroups).map(&:name))
  end
end
