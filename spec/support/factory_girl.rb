RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    begin
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean_with :truncation
    end
  end
end
