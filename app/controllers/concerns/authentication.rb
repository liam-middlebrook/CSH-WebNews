module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    authenticated_user or render 'shared/authenticate', layout: false
  end

  def authenticated_user
    @authenticated_user ||= if authenticated_username.present?
      User.find_or_initialize_by(username: authenticated_username).tap do |user|
        user.update!(display_name: request.env[ENV_DISPLAY_NAME])
      end
    end
  end

  def authenticated_username
    request.env[ENV_USERNAME]
  end
end
