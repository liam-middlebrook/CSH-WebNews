RSpec.configure do |config|
  config.before do
    # Avoid hitting the live news server during testing
    hide_const('Net::NNTP')

    # Avoid shelling out to `groups` with fake usernames during testing
    allow_any_instance_of(User).to receive(:unix_groups).and_return([])

    # Immediately raise any errors that would be sent through the notifier
    allow(ExceptionNotifier).to receive(:notify_exception){ |error| raise error }
  end
end
