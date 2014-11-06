class PagesController < ApplicationController
  before_filter :get_newsgroups_for_nav, only: [:home, :check_new]
  before_filter :get_newsgroup, only: :check_new
  before_filter :get_post, only: :check_new
  before_filter :allow_cross_origin_access, only: :home
  skip_before_filter :check_auth, :get_or_create_user, only: :authenticate

  def home
    if params[:no_user_override]
      redirect_to root_path and return
    end

    respond_to do |wants|

      wants.html do
        if request.env[ENV_REALNAME]
          @current_user.real_name = request.env[ENV_REALNAME]
          @current_user.save!
        end
        get_last_sync_time
        get_next_unread_post
      end

      wants.js do
        get_activity_feed
        get_next_unread_post
      end

      wants.json do
        get_activity_feed
        render json: { activity: @activity }
      end

    end
  end

  def check_new
    get_last_sync_time
    get_next_unread_post
    if params[:location] == '#!/home'
      @dashboard_active = true
      get_activity_feed
    end
  end

  def about
    render 'shared/dialog'
  end

  def new_user
    render 'shared/dialog'
  end

  def old_user
    render 'shared/dialog'
  end

  def rss_caution
    render 'shared/dialog'
  end

  def authenticate
    render 'shared/authenticate'
  end

  private

    def get_activity_feed
      newest_in_stickies = Post.sticky.order(date: :desc).
        map{ |post| post.root.subtree.order(:date).last }
      newest_in_threads = Post.joins(:postings).
        where(postings: { newsgroup_id: Newsgroup.default_filtered.ids }).
        where('date > ?', 1.month.ago).order(date: :desc)
      activity_posts = (newest_in_stickies | newest_in_threads).uniq(&:root_id)[0..20]

      @activity = activity_posts.map do |post|
        unread_count = post.root.unread_count_in_thread_for_user(@current_user)
        {
          thread_parent: post.root,
          newest_post: post,
          cross_posted: post.crossposted?,
          next_unread: @current_user.unread_posts.merge(post.root.subtree).order(:date).first,
          post_count: post.root.subtree.count,
          unread_count: unread_count,
          personal_class: post.root.personal_class_for_user(@current_user),
          unread_class: (unread_count > 0 ? post.root.unread_personal_class_for_user(@current_user) : nil)
        }
      end
    end
end