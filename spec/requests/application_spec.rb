require 'rails_helper'

RSpec.describe 'Application' do
  it 'refuses access if the correct Accept header is not used' do
    get user_path, nil, accept: 'application/json'

    expect(response.code).to eq '406' # Not Acceptable
  end

  it 'refuses access if the correct Content-Type header is not used' do
    get user_path, nil, 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

    expect(response.code).to eq '415' # Unsupported Media Type
  end

  it 'refuses access if maintenance mode is on, providing the reason' do
    Flag.maintenance_mode_on!('test reason')

    get user_path

    expect(response.code).to eq '503' # Service Unavailable
    expect(response.headers['X-Maintenance-Reason']).to eq 'test reason'
  end
end
