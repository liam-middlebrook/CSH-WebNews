class PostsController < BaseController
  def index
    indexer = PostIndexer.new(indexer_params)

    if indexer.valid?
      respond_with indexer.results, meta: indexer.meta, each_serializer: serializer
    else
      respond_with({ errors: indexer.errors }, status: :unprocessable_entity)
    end
  end

  def show
    respond_with post, serializer: serializer
  end

  def create
    respond_with_message NNTP::NewPostMessage.new(new_post_params)
  end

  def destroy
    respond_with_message NNTP::CancelMessage.new(cancel_params)
  end

  private

  def indexer_params
    params.permit(PostIndexer.attribute_names).merge(user: current_user)
  end

  def new_post_params
    { posting_host: remote_host }
      .merge(params.permit(NNTP::NewPostMessage.attribute_names))
      .merge(user: current_user, user_agent: current_application.name)
  end

  def cancel_params
    { posting_host: remote_host }
      .merge(params.permit(NNTP::CancelMessage.attribute_names))
      .merge(post: post, user: current_user, user_agent: current_application.name)
  end

  def respond_with_message(message)
    new_post = message.send!

    if new_post.present?
      respond_with new_post, location: new_post
    else
      if message.was_accepted
        head :accepted # The server probably moderated or spam-filtered it
      else
        respond_with message
      end
    end
  end

  def post
    post = Post.find(params[:id])
    threading? ? post.root : post
  end

  def serializer
    threading? ? ThreadSerializer : PostSerializer
  end

  def threading?
    ActiveRecord::ConnectionAdapters::Column.value_to_boolean(
      params[:as_threads].presence || params[:as_thread].presence
    )
  end
end
