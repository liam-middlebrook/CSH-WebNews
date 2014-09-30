class BaseController < ActionController::Base
  respond_to :json
  before_action :require_accept_type, :require_content_type, :require_no_maintenance
  doorkeeper_for :all
  serialization_scope :current_user

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

  def require_no_maintenance
    if Flag.maintenance_mode?
      headers['X-Maintenance-Reason'] = Flag.maintenance_reason
      head :service_unavailable
    end
  end
end
