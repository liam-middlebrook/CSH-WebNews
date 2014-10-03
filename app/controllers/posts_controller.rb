class PostsController < BaseController
  def show
    respond_with Post.find(params[:id])
  end
end
