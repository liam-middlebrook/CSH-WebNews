# == Schema Information
#
# Table name: starred_post_entries
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  post_id    :integer
#  created_at :datetime
#
# Indexes
#
#  index_starred_post_entries_on_post_id              (post_id)
#  index_starred_post_entries_on_user_id              (user_id)
#  index_starred_post_entries_on_user_id_and_post_id  (user_id,post_id) UNIQUE
#

class StarredPostEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :post

  validates! :user, :post, presence: true
  validates! :user_id, uniqueness: { scope: :post_id }
end
