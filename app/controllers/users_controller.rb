class UsersController < ApplicationController
  before_filter :prevent_api_access, only: [:edit, :update, :update_api]
  before_filter :allow_cross_origin_access, only: [:show, :unread_counts]
  before_filter :get_newsgroups_for_search, only: :edit

  def show
    render json: {
      user: @current_user.as_json(only: [:username, :real_name, :created_at]).
        merge(is_admin: @current_user.admin?).
        merge(preferences: @current_user.preferences.slice(:thread_mode, :time_zone))
    }
  end

  def edit
    render 'shared/dialog'
  end

  def update
    if not @current_user.update_attributes(user_params)
      form_error(@current_user.errors.full_messages.join(', '))
    end
  end

  def update_api
    if params[:disable]
      @current_user.update_attributes(api_key: nil, api_data: nil)
    elsif params[:enable]
      key = SecureRandom.hex(8) until !key.nil? && User.find_by_api_key(key).nil?
      @current_user.update_attributes(api_key: key, api_data: nil)
    end
  end

  def unread_counts
    render json: {
      unread_counts: {
        normal: @current_user.unread_count,
        in_thread: @current_user.unread_count_in_thread,
        in_reply: @current_user.unread_count_in_reply
      }
    }
  end

  private

  def user_params
    subscription_attributes = [
      :id, :_destroy, :newsgroup_name, :unread_level, :email_level, :digest_type
    ]
    params.require(:user).permit(
      preferences: [:theme, :thread_mode, :time_zone],
      default_subscription_attributes: subscription_attributes,
      subscriptions_attributes: subscription_attributes
    )
  end
end
