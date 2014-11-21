require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Load WebNews configuration constants
require File.expand_path('../webnews', __FILE__)

module Webnews
  class Application < Rails::Application
    require 'shellwords'
    require 'resolv'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # TODO: Go back to schema.rb if this issue is ever addressed
    # https://github.com/dockyard/postgres_ext/issues/139
    config.active_record.schema_format = :sql

    # Allow cross-origin requests to non-OAuth endpoints from secure local sites
    config.middleware.insert_before 0, 'Rack::Cors' do
      allow do
        origins %r(^https://[^/]*\.#{LOCAL_DOMAIN}$)
        resource %r(^(?!/oauth)), headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
      end
    end
  end
end
