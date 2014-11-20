require 'rails_helper'

RSpec.describe 'Unreads destroy' do
  it 'marks the specified posts as read' do
    target_posts = create_list(:post, 3, unread_for: oauth_user)
    other_posts = create_list(:post, 2, unread_for: oauth_user)

    delete unreads_path, post_ids: target_posts.map(&:id).join(',')

    expect(response.status).to be 204
    get posts_path(min_unread_level: 0)
    expect(response_json[:meta][:matched_ids]).to match_array other_posts.map(&:id)
  end
end
