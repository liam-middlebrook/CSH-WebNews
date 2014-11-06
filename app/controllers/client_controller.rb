class ClientController < ActionController::Base
  before_action :prevent_framing

  def show
    if user_authenticated?
      update_or_create_user!
      render layout: false
    else
      render 'shared/authenticate', layout: false
    end
  end

  private

  def authenticated_username
    request.env[ENV_USERNAME]
  end

  def update_or_create_user!
    user = User.find_or_initialize_by(username: authenticated_username)
    user.real_name = request.env[ENV_REALNAME]
    user.save!
  end

  def prevent_framing
    headers['X-Frame-Options'] = 'DENY'
  end

  def user_authenticated?
    authenticated_username.present?
  end
end
