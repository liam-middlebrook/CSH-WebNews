class API::NewsgroupsController < API::BaseController
  def index
    respond_with Newsgroup.all, each_serializer: NewsgroupSerializer
  end
end
