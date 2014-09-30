class UsersController < BaseController
  def show
    respond_with current_user
  end
end
