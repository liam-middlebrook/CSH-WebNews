# == Schema Information
#
# Table name: unreads
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  post_id        :text             not null
#  personal_level :integer          not null
#  user_created   :boolean          default(FALSE)
#
# Indexes
#
#  index_unreads_on_post_id              (post_id)
#  index_unreads_on_user_id              (user_id)
#  index_unreads_on_user_id_and_post_id  (user_id,post_id) UNIQUE
#

class Unread < ActiveRecord::Base
  belongs_to :user
  belongs_to :post

  after_initialize :assign_personal_level
  before_save :assign_personal_level

  private

  def assign_personal_level
    # FIXME: Post or user could be changed after initialization, and personal
    # level would not update to match. In practice this never happens though.
    if personal_level.nil? && post.present? && user.present?
      self.personal_level = post.personal_level_for(user)
    end
  end
end