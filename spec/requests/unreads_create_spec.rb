require 'rails_helper'

RSpec.describe 'Unreads create' do
  it 'marks the specified posts as unread' do
    target_posts = create_list(:post, 3)
    other_posts = create_list(:post, 2)

    post unreads_path, post_ids: target_posts.map(&:id).join(',')

    expect(response.status).to be 201
    get posts_path(only_unread: true)
    expect(response_json[:meta][:matched_ids]).to match_array target_posts.map(&:id)
    expect(response_json[:posts].first[:unread_class]).to eq 'manual'
  end

  it 'returns an appropriate status when nonexistent post IDs are given' do
    post unreads_path, post_ids: [create(:post).id, -1].join(',')

    expect(response.status).to be 404
  end
end
