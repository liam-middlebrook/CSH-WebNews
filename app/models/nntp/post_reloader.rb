module NNTP
  class PostReloader
    def initialize(post)
      @post = post
    end

    def reload!
      Flag.with_news_sync_lock do
        old_post_id = @post.delete.id
        importer = PostImporter.new(newsgroup: @post.newsgroup, quiet: true)
        new_post = importer.import!(
          number: @post.number,
          article: Server.article(@post.newsgroup_name, @post.number)
        )
        new_post.update!(id: old_post_id)
      end
    end
  end
end
