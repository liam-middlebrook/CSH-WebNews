RSpec.configure do |config|
  config.prepend_before(:suite) do
    DatabaseCleaner.clean_with :truncation
  end
end
