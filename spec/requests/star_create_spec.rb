require 'rails_helper'

RSpec.describe 'Star create' do
  it 'stars the specified post for the current user' do
    post = create(:post)

    post post_star_path(post)

    expect(response.status).to be 201
    get post_path(post)
    expect(response_json[:post][:is_starred]).to be true
  end
end
