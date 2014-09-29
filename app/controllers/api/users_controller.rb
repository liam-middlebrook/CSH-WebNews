class API::UsersController < API::BaseController
  def show
    # TODO: Remove `serializer` parameters once controllers are de-namespaced
    respond_with current_user, serializer: UserSerializer
  end
end
