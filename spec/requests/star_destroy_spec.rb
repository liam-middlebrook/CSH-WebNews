require 'rails_helper'

RSpec.describe 'Star destroy' do
  it 'unstars the specified post for the current user' do
    post = create(:post, starred_by: oauth_user)

    delete post_star_path(post)

    expect(response.status).to be 204
    get post_path(post)
    expect(response_json[:post][:is_starred]).to be false
  end
end
