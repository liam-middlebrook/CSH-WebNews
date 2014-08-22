require 'exception_notification/rails'

ExceptionNotification.configure do |config|
  config.ignore_if{ not Rails.env.production? }

  config.add_notifier :email, {
    email_prefix: "Error:",
    sender_address: %Q("WebNews" <webnews@#{LOCAL_DOMAIN}>),
    exception_recipients: ["webnews-admin@#{LOCAL_DOMAIN}"],
    email_format: :html
  }
end
