class PostsController < BaseController
  def show
    if params[:thread].present?
      respond_with post.root, serializer: ThreadSerializer
    else
      respond_with post
    end
  end

  private

  def post
    Post.find(params[:id])
  end
end
