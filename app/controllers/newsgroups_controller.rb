class NewsgroupsController < ApplicationController
  before_filter :get_newsgroup, :only => :show
  
  def index
    render :json => { :newsgroups => Newsgroup.all.as_json(:for_user => @current_user) }
  end
  
  def show
    render :json => { :newsgroup => @newsgroup.as_json(:for_user => @current_user) }
  end
end
