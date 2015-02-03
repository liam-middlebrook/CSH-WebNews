RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.cleaning do
      FactoryGirl.lint
    end
  end
end
