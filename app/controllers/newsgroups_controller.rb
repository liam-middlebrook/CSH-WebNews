class NewsgroupsController < BaseController
  def index
    respond_with Newsgroup.all, meta: { last_sync_at: Flag.last_full_news_sync_at }
  end
end
