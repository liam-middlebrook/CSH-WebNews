# == Schema Information
#
# Table name: postings
#
#  id           :integer          not null, primary key
#  newsgroup_id :text             not null
#  post_id      :text             not null
#  number       :integer          not null
#  top_level    :boolean          default(FALSE), not null
#
# Indexes
#
#  index_postings_on_newsgroup_id              (newsgroup_id)
#  index_postings_on_newsgroup_id_and_post_id  (newsgroup_id,post_id) UNIQUE
#  index_postings_on_post_id                   (post_id)
#

class Posting < ActiveRecord::Base
  belongs_to :newsgroup
  belongs_to :post

  validates! :number, presence: true

  before_save :update_top_level

  private

  def update_top_level
    # We are "top level" if our post is a root, or our post's parent is not
    # posted in our newsgroup
    self.top_level = post.root? ||
      !post.parent.postings.pluck(:newsgroup_id).include?(newsgroup_id)
    true # Avoid possibly returning false and canceling the save
  end
end
