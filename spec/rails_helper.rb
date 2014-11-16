ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  config.include NNTPHelper
  config.include OauthHelper

  config.before(:suite) do
    # Set time zone so things like 2.minutes.ago in a spec are using the same
    # zone as the server will be returning times in (assuming a default user)
    Time.zone = DEFAULT_TIME_ZONE
  end
end
