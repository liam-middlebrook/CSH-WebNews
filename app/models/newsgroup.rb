# == Schema Information
#
# Table name: newsgroups
#
#  id          :text             not null, primary key
#  status      :text
#  created_at  :datetime
#  updated_at  :datetime
#  description :text
#

class Newsgroup < ActiveRecord::Base
  with_options dependent: :destroy do |assoc|
    assoc.has_many :postings
    assoc.has_many :posts, through: :postings
    assoc.has_many :subscriptions, foreign_key: :newsgroup_name, primary_key: :name
  end

  has_many :unread_post_entries, through: :posts

  def self.cancel
    find('control.cancel')
  end

  def control?
    true if id[/^control\./]
  end

  def posting_allowed?
    status == 'y'
  end

  def self.where_posting_allowed
    where(status: 'y')
  end

  def self.default_filtered
    where("newsgroups.id NOT SIMILAR TO '#{DEFAULT_NEWSGROUP_FILTER}'")
  end
end
