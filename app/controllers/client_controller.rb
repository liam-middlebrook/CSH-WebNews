class ClientController < ActionController::Base
  include Authentication
  before_action :authenticate_user!

  def show
    render layout: false
  end
end
