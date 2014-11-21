class ClientController < ActionController::Base
  include Authentication

  def show
    render layout: false
  end
end
