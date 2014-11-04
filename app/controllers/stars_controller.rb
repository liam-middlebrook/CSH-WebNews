class StarsController < BaseController
  def create
    post.starred_post_entries.find_or_create_by!(user_id: current_user.id)
    head :created
  end

  def destroy
    post.starred_post_entries.find_by(user_id: current_user.id).try(:destroy!)
    head :no_content
  end

  private

  def post
    Post.find(params[:post_id])
  end
end
