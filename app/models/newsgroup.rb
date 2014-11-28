# == Schema Information
#
# Table name: newsgroups
#
#  id          :integer          not null, primary key
#  name        :text
#  status      :text
#  created_at  :datetime
#  updated_at  :datetime
#  description :text
#
# Indexes
#
#  index_newsgroups_on_name  (name) UNIQUE
#

class Newsgroup < ActiveRecord::Base
  with_options dependent: :destroy do |assoc|
    assoc.has_many :postings
    assoc.has_many :posts, through: :postings
    assoc.has_many :subscriptions, foreign_key: :newsgroup_name, primary_key: :name
  end

  has_many :unread_post_entries, through: :posts

  validates! :name, presence: true, uniqueness: true

  def self.cancel
    find_by!(name: 'control.cancel')
  end

  def control?
    true if name[/^control\./]
  end

  def posting_allowed?
    status == 'y'
  end

  def self.where_posting_allowed
    where(status: 'y')
  end

  def self.default_filtered
    where("newsgroups.name NOT SIMILAR TO '#{DEFAULT_NEWSGROUP_FILTER}'")
  end
end
