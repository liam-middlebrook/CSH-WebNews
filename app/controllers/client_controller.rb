class ClientController < ActionController::Base
  before_action :prevent_framing

  def show
    if request.env[ENV_USERNAME].present?
      render layout: false
    else
      render 'shared/authenticate', layout: false
    end
  end

  private

  def prevent_framing
    headers['X-Frame-Options'] = 'DENY'
  end
end
