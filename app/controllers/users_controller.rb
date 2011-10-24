class UsersController < ApplicationController
  def edit
    render 'shared/dialog'
  end
  
  def update
    @current_user.update_attributes(params[:user])
    Newsgroup.find_each do |newsgroup|
      if not @current_user.unread_in_group?(newsgroup)
        UnreadPostEntry.where(:user_id => @current_user.id, :newsgroup_id => newsgroup.id).delete_all
      end
    end
  end
end
