class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  def index
    @applications = current_resource_owner.oauth_applications
  end

  def create
    @application = Doorkeeper::Application.new(application_params)
    @application.owner = current_resource_owner if Doorkeeper.configuration.confirm_application_owner?
    if @application.save
      flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :create])
      respond_with :oauth, @application, location: oauth_application_url( @application )
    else
      render :new
    end
  end
end
