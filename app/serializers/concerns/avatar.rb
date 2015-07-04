module Avatar
  extend ActiveSupport::Concern

  private

  def avatar_url_for(email)
    digest = Digest::MD5.hexdigest(email.to_s.gsub(/\s+/, '').downcase)
    "https://secure.gravatar.com/avatar/#{digest}?default=mm&rating=pg"
  end
end
