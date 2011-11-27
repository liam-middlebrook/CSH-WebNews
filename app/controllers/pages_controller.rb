class PagesController < ApplicationController
  before_filter :get_newsgroups_for_nav, :only => [:home, :check_new]
  before_filter :get_newsgroup, :only => :check_new
  before_filter :get_post, :only => :check_new

  def home
    respond_to do |wants|
      
      wants.html do
        set_no_cache
        @current_user.real_name = request.env['WEBAUTH_LDAP_CN']
        @current_user.save!
        sync_posts
      end
      
      wants.js do
        get_activity_feed
        get_next_unread_post
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
  
  def check_new
    sync_posts
    clean_old_unread
    if params[:location] == '#!/home'
      @dashboard_active = true
      get_activity_feed
    end
  end
  
  def mark_read
    if params[:newsgroup]
      @current_user.unread_post_entries.
        where(:newsgroup_id => Newsgroup.find_by_name(params[:newsgroup]).id).destroy_all
    else
      @current_user.unread_post_entries.destroy_all
    end
    get_next_unread_post
  end
  
  private
    
    def get_activity_feed
      unread_posts = @current_user.unread_posts
      recent_posts = Post.where('date > ?', 1.week.ago)
      @unread_threads = build_thread_activity_data(unread_posts)
      @recent_threads = build_thread_activity_data(recent_posts, RECENT_EXCLUDE)
      @recent_threads.reject!{ |rt| @unread_threads.index{ |ut| ut[:parent] == rt[:parent] } }
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
          threads << {
            :parent => parent,
            :date => post.date,
            :posts => 1,
            :authors => [maybe_you(parent.author_name)],
            :oldest => post
          }
        else
          threads[i][:posts] += 1
          threads[i][:authors] |= [maybe_you(post.author_name)]
          if threads[i][:date] < post.date
            threads[i][:date] = post.date
          end
        end
      end
      
      # Sub-optimal, could result in cross-posted threads with new replies not being shown
      # if the replies are not in the thread's "primary" newsgroup (rarely happens)
      threads.reject! do |thread|
        parent = thread[:parent]
        parent.is_crossposted? and
          (parent.followup_newsgroup and parent.followup_newsgroup != parent.newsgroup) or
          (!parent.followup_newsgroup and
            parent.in_all_newsgroups.length > 1 and
            parent != parent.in_all_newsgroups[0])
      end
      
      return threads.sort{ |x,y| y[:date] <=> x[:date] }
    end
    
    def clean_old_unread
      if not File.exists?('tmp/lastclean.txt') or
          File.mtime('tmp/lastclean.txt') < 1.day.ago
        FileUtils.touch('tmp/lastclean.txt')
        User.inactive.each do |user|
          UnreadPostEntry.where(:user_id => user.id).delete_all
        end
      end
    end
    
    def sync_posts
      if not File.exists?('tmp/syncing.txt') and
          (not File.exists?('tmp/lastsync.txt') or
            File.mtime('tmp/lastsync.txt') < 1.minute.ago)
        begin
          Newsgroup.sync_all!
        rescue
          puts "\n\n### SYNC ERROR ###"
          puts $!.message
          puts "##################\n\n"
        end
      end
      get_last_sync_time
      get_next_unread_post
    end
    
    def get_last_sync_time
      @last_sync_time = File.mtime('tmp/lastsync.txt')
      @show_sync_warning = true if @last_sync_time < 2.minutes.ago
    end
    
    def maybe_you(name)
      name == @current_user.real_name ? 'you' : name
    end
end
