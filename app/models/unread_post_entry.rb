# == Schema Information
#
# Table name: unread_post_entries
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  post_id        :integer
#  personal_level :integer
#  user_created   :boolean
#
# Indexes
#
#  index_unread_post_entries_on_post_id              (post_id)
#  index_unread_post_entries_on_user_id              (user_id)
#  index_unread_post_entries_on_user_id_and_post_id  (user_id,post_id) UNIQUE
#

class UnreadPostEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :post

  validates! :user, :post, presence: true
  validates! :user_id, uniqueness: { scope: :post_id }

  after_initialize :assign_personal_level
  before_save :assign_personal_level

  private

  def assign_personal_level
    # FIXME: Post or user could be changed after initialization, and personal
    # level would not update to match. In practice this never happens though.
    if personal_level.nil? && post.present? && user.present?
      self.personal_level = post.personal_level_for_user(user)
    end
  end
end
