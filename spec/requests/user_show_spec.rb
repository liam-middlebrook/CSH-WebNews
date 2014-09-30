require 'rails_helper'

RSpec.describe 'User show' do
  it 'retrieves info about the current user' do
    get user_path

    expect(response).to be_successful
    expect(response_json).to eq({
      user: {
        username: oauth_user.username,
        display_name: oauth_user.real_name,
        created_at: oauth_user.created_at.iso8601,
        is_admin: oauth_user.admin?,
        thread_mode: oauth_user.thread_mode.to_s
      }
    })
  end
end
