class NewsgroupsController < BaseController
  def index
    respond_with Newsgroup.all
  end
end
