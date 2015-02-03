class PostsController < BaseController
  def index
    respond_with_indexer PostIndexer.new(indexer_params)
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

  def respond_with_indexer(indexer)
    if indexer.valid?
      if indexer.as_meta
        respond_with meta: indexer.meta
      else
        respond_with indexer.results, meta: indexer.meta, each_serializer: serializer
      end
    else
      respond_with({ errors: indexer.errors }, status: :unprocessable_entity)
    end
  end

  def respond_with_message(message)
    new_post = message.transmit

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
    post = if params[:id].include?('@')
      Post.find_by!(message_id: params[:id])
    else
      Post.find(params[:id])
    end

    threading? ? post.root : post
  end

  def serializer
    threading? ? ThreadSerializer : PostSerializer
  end

  def threading?
    threading_value.present? &&
      !ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES.include?(threading_value)
  end

  def threading_value
    params[:as_threads].presence || params[:as_thread].presence
  end
end
