class UnreadsController < BaseController
  before_action :ensure_posts_exist

  def create
    post_ids.each do |post_id|
      current_user.unread_post_entries
        .find_or_initialize_by(post_id: post_id).update!(user_created: true)
    end

    head :created
  end

  def destroy
    current_user.unread_post_entries.where(post_id: post_ids).each(&:destroy!)
    head :no_content
  end

  private

  def post_ids
    params.require(:post_ids).split(',')
  end

  def ensure_posts_exist
    head :not_found if Post.where(id: post_ids).size != post_ids.size
  end
end
