require 'rails_helper'

RSpec.describe 'Application' do
  it 'refuses access if an invalid OAuth token is provided' do
    get user_path, nil, authorization: 'Bearer 12345'

    expect(response.status).to be 401 # Unauthorized
  end

  it 'permits access without an OAuth token if a Webauth username is present' do
    create(:user, username: 'adelaide')

    get user_path, nil, authorization: nil, ENV_USERNAME => 'adelaide'

    expect(response.status).to be 200
  end

  it 'refuses cross-origin access when a Webauth username is present' do
    create(:user, username: 'adelaide')

    get user_path, nil,
      authorization: nil, ENV_USERNAME => 'adelaide', 'Origin' => 'example.com'

    expect(response.status).to be 401 # Unauthorized
  end

  it 'refuses access if the correct Accept header is not used' do
    get user_path, nil, accept: 'application/json'

    expect(response.status).to be 406 # Not Acceptable
  end

  it 'refuses access to non-GET endpoints if the Content-Type is incorrect' do
    post unreads_path, nil, 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

    expect(response.status).to be 415 # Unsupported Media Type
  end

  it 'permits access to GET endpoints regardless of Content-Type' do
    get user_path, nil, 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

    expect(response.status).to be 200
  end

  it 'refuses access if maintenance mode is on, providing the reason' do
    Flag.maintenance_mode_on!('test reason')

    get user_path

    expect(response.status).to be 503 # Service Unavailable
    expect(response.headers['X-Maintenance-Reason']).to eq 'test reason'
  end
end
