class Posting < ActiveRecord::Base
  belongs_to :newsgroup
  belongs_to :post

  validates! :newsgroup, :post, :number, presence: true
  validates! :newsgroup_id, uniqueness: { scope: :post_id }

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
