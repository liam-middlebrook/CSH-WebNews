class API::BaseController < ActionController::Base
  respond_to :json
  before_action :require_accept_type, :require_content_type
  doorkeeper_for :all

  private

  def current_user
    @current_user ||= User.find(doorkeeper_token.resource_owner_id)
  end

  def require_accept_type
    if request.headers['Accept'] == 'application/vnd.csh.webnews.v1+json'
      request.format = :json
    else
      head :not_acceptable
    end
  end

  def require_content_type
    if request.content_type != 'application/json'
      head :unsupported_media_type
    end
  end
end
