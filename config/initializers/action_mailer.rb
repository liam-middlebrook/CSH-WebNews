ActionMailer::Base.tap do |mailer|
  mailer.default :from => %Q("WebNews" <webnews@#{LOCAL_DOMAIN}>)
  mailer.default_url_options = { :host => SERVER_NAME, :protocol => 'https' }
  mailer.delivery_method = :sendmail
  mailer.sendmail_settings = {}
  # Above removes ActionMailer's bad sendmail options, allowing mail gem's
  # better options to take over. See https://github.com/mikel/mail/issues/70
end
