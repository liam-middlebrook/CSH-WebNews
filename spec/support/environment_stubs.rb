RSpec.configure do |config|
  config.before do
    # Avoid shelling out to `groups` with fake usernames during testing
    allow_any_instance_of(User).to receive(:unix_groups).and_return([])
  end
end
