class PagesController < ApplicationController
  before_filter :get_newsgroups_for_nav, :only => [:home, :check_new]
  before_filter :get_newsgroup, :only => :check_new
  before_filter :get_post, :only => :check_new

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
        cronless_sync_all
        get_last_sync_time
        get_next_unread_post
      end
      
      wants.js do
        get_activity_feed
        get_next_unread_post
      end
      
      wants.json do
        get_activity_feed
        render :json => {
          :activity => {
            :sticky => @sticky_threads,
            :unread => @unread_threads,
            :recent => @recent_threads
          }
        }
      end
      
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
  
  def check_new
    cronless_sync_all
    get_last_sync_time
    get_next_unread_post
    if params[:location] == '#!/home'
      @dashboard_active = true
      get_activity_feed
    end
  end
  
  private
    
    def get_activity_feed
      unread_posts = @current_user.unread_posts
      recent_posts = Post.where('date > ?', 1.week.ago)
      sticky_posts = Post.where('sticky_until > ?', Time.now).map{ |p| p.all_in_thread }.flatten
      @sticky_threads = build_thread_activity_data(sticky_posts)
      @unread_threads = build_thread_activity_data(unread_posts)
      @recent_threads = build_thread_activity_data(recent_posts, RECENT_EXCLUDE)
      @recent_threads.reject!{ |rt| @unread_threads.index{ |ut| ut[:parent] == rt[:parent] } }
      @recent_threads.reject!{ |rt| @sticky_threads.index{ |st| st[:parent] == rt[:parent] } }
      @unread_threads.reject!{ |ut| @sticky_threads.index{ |st| st[:parent] == ut[:parent] } }
    end
    
    def build_thread_activity_data(posts, exclude = nil)
      posts.reject! do |post|
        # Won't reject posts that are crossposted to multiple excluded groups,
        # though this pretty much never happens
        !post.newsgroup.posting_allowed? || (
          !exclude.nil? && post.newsgroup.name[exclude] && !post.is_crossposted?(true)
        )
      end
      
      threads = []
      posts.each do |post|
        parent = post.thread_parent
        i = threads.index{ |t| t[:parent] == parent }
        if i.nil?
          unread = post.unread_for_user?(@current_user)
          threads << {
            :parent => parent,
            :date => post.date,
            :oldest => post,
            :posts => 1,
            :authors => [maybe_you(post.author_name)],
            :unread => unread,
            :oldest_unread => unread ? post : nil,
            :unread_posts => unread ? 1 : 0,
            :unread_authors => unread ? [maybe_you(post.author_name)] : []
          }
        else
          threads[i][:posts] += 1
          threads[i][:authors] |= [maybe_you(post.author_name)]
          if threads[i][:date] < post.date
            threads[i][:date] = post.date
          end
          if post.unread_for_user?(@current_user)
            threads[i][:unread] = true
            threads[i][:oldest_unread] ||= post
            threads[i][:unread_posts] += 1
            threads[i][:unread_authors] |= [maybe_you(post.author_name)]
          end
        end
      end
      
      threads.map! do |thread|
        thread.merge(:personal_class => thread[:unread] ?
          thread[:parent].thread_unread_class_for_user(@current_user) :
          thread[:parent].personal_class_for_user(@current_user))
      end
      
      # Sub-optimal, could result in cross-posted threads with new replies not being shown
      # if the replies are not in the thread's "primary" newsgroup (rarely happens)
      threads.reject! do |thread|
        parent = thread[:parent]
        parent.is_crossposted? and
          (parent.followup_newsgroup and
            parent.followup_newsgroup != parent.newsgroup and
            parent.exists_in_followup_newsgroup?) or
          ((!parent.followup_newsgroup or !parent.exists_in_followup_newsgroup?) and
            parent.in_all_newsgroups.length > 1 and
            parent != parent.in_all_newsgroups[0])
      end
      
      return threads.sort{ |x,y| y[:date] <=> x[:date] }
    end
end
