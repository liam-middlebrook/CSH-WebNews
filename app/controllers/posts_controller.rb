class PostsController < BaseController
  def index
    indexer = PostIndexer.new(indexer_params.merge(user: current_user))

    if indexer.valid?
      respond_with indexer.results, meta: indexer.meta, each_serializer: serializer
    else
      respond_with({ errors: indexer.errors }, status: :unprocessable_entity)
    end
  end

  def show
    respond_with post, serializer: serializer
  end

  private

  def indexer_params
    params.permit(PostIndexer.attribute_names)
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
