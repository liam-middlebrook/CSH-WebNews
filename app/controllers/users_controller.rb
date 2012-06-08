class UsersController < ApplicationController
  def edit
    render 'shared/dialog'
  end
  
  def update
    @current_user.update_attributes(params[:user].except(:username, :real_name))
    Newsgroup.find_each do |newsgroup|
      if not @current_user.unread_in_group?(newsgroup)
        UnreadPostEntry.where(:user_id => @current_user.id, :newsgroup_id => newsgroup.id).delete_all
      end
    end
  end
  
  def update_api
    if params[:disable]
      @current_user.update_attributes(:api_key => nil, :api_last_access => nil, :api_last_agent => nil)
    elsif params[:enable]
      key = SecureRandom.hex(8) until !key.nil? && User.find_by_api_key(key).nil?
      @current_user.update_attributes(:api_key => key, :api_last_access => nil, :api_last_agent => nil)
    end
  end
end
