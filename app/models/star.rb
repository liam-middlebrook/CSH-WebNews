# == Schema Information
#
# Table name: stars
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  post_id    :text             not null
#  created_at :datetime
#
# Indexes
#
#  index_stars_on_post_id              (post_id)
#  index_stars_on_user_id              (user_id)
#  index_stars_on_user_id_and_post_id  (user_id,post_id) UNIQUE
#

class Star < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
end
