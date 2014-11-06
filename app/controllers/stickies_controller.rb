class StickiesController < BaseController
  def update
    sticker = PostSticker.new(sticker_params)
    sticker.stick
    respond_with sticker
  end

  private

  def sticker_params
    params.permit(:expires_at).merge(user: current_user, post: post)
  end

  def post
    Post.find(params[:post_id])
  end
end
