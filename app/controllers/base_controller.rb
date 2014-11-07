class BaseController < ActionController::Base
  respond_to :json
  doorkeeper_for :all
  before_action :require_accept_type,
    :require_content_type,
    :require_no_maintenance,
    :respect_user_time_zone
  serialization_scope :current_user

  rescue_from StandardError do |error|
    head :internal_server_error
    ExceptionNotifier.notify_exception(error)
  end

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActiveRecord::RecordNotUnique do |error|
    head :conflict
    ExceptionNotifier.notify_exception(error)
  end

  private

  def current_application
    @current_application ||= doorkeeper_token.application
  end

  def current_user
    @current_user ||= User.find(doorkeeper_token.resource_owner_id)
  end

  def remote_host
    Resolv.getname(request.remote_ip) rescue request.remote_ip
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

  def respect_user_time_zone
    # FIXME: Not thread-safe. Should be Time.use_zone, but that doesn't work
    # with Chronic, see https://github.com/mojombo/chronic/pull/214 and related
    Time.zone = current_user.time_zone
    Chronic.time_class = Time.zone
  end
end
