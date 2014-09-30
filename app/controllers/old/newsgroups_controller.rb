class NewsgroupsController < ApplicationController
  before_filter :get_newsgroup, only: :show
  before_filter :get_last_sync_time, only: :index
  before_filter :allow_cross_origin_access, only: [:index, :show]

  def index
    render json: { newsgroups: Newsgroup.all.as_json(for_user: @current_user) }.merge(json_sync_warning)
  end

  def show
    render json: { newsgroup: @newsgroup.as_json(for_user: @current_user) }
  end
end
