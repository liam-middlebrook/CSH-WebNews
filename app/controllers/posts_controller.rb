class PostsController < ApplicationController
  before_filter :get_newsgroup, :only => [:index, :search, :search_entry, :show, :new]
  before_filter :get_post, :only => [:show, :new, :destroy, :destroy_confirm, :edit_sticky, :update_sticky]
  before_filter :get_newsgroups_for_search, :only => :search_entry
  before_filter :get_newsgroups_for_posting, :only => [:new, :create]
  before_filter :set_list_layout_and_offset, :only => [:index, :search]

  def index
    @not_found = true if params[:not_found]
    @flat_mode = true if @current_user.thread_mode == :flat
    
    if params[:showing]
      @showing = @newsgroup.posts.find_by_number(params[:showing])
      if @flat_mode
        @showing_thread = @showing
      else
        @showing_thread = @showing.thread_parent
      end
      @from_older = @showing_thread.date
      @from_newer = @showing_thread.date
    end
    
    limit = (@from_older and @from_newer) ? 5 : 9
    limit *= 2 if @flat_mode
    
    if not (@from_older or @from_newer)
      @from_older = Post.order('date').last.date + 1.second
    end
    
    if @from_older
      if @flat_mode
        @posts_older = @newsgroup.posts.where('date < ?', @from_older).order('date DESC').limit(limit)
      else
        @posts_older = @newsgroup.posts.
          where('parent_id = ? and date < ?', '', @from_older).
          order('date DESC').limit(limit)
      end
    end
    
    if @from_newer
      if @flat_mode
        @posts_newer = @newsgroup.posts.where('date > ?', @from_newer).order('date').limit(limit)
      else
        @from_newer = @newsgroup.posts.where(:date => @from_newer).first.thread_parent.date
        @posts_newer = @newsgroup.posts.
          where('parent_id = ? and date > ?', '', @from_newer).
          order('date').limit(limit)
      end
    end
    
    if @posts_older
      @more_older = @posts_older.length > 0 && !@posts_older[limit - 1].nil?
      @posts_older.delete_at(-1) if @posts_older.length == limit
    end
    if @posts_newer
      @more_newer = @posts_newer.length > 0 && !@posts_newer[limit - 1].nil?
      @posts_newer.delete_at(-1) if @posts_newer.length == limit
    end
    
    if not @flat_mode
      flatten = (@current_user.thread_mode == :hybrid)
      @showing_thread = @showing_thread.thread_tree_for_user(@current_user, flatten) if @showing_thread
      [@posts_older, @posts_newer].each do |posts|
        posts.map!{ |post| post.thread_tree_for_user(@current_user, flatten) } if posts
      end
    end
    
    get_next_unread_post
  end
  
  def search
    limit = 18
    conditions, values, error_text = build_search_conditions
    
    if @from_older
      conditions << 'date < ?'
      values << @from_older
    end
    if not @newsgroup
      conditions << 'newsgroup not like ?'
      values << 'control%'
    end
    
    if params[:validate]
      if error_text
        form_error error_text
      else
        search_params = params.except(:action, :controller, :source, :commit, :validate, :utf8, :_)
        render :partial => 'search_redirect', :locals => { :search_params => search_params }
      end
      return
    elsif error_text
      # Should only happen if someone messes with URLs
      render :nothing => true and return
    end
    
    @search_mode = @flat_mode = true
    @posts_older = Post.where(conditions.join(' and '), *values).order('date DESC').limit(limit)
    @more_older = @posts_older.length > 0 && !@posts_older[limit - 1].nil?
    @posts_older.delete_at(-1) if @posts_older.length == limit
    
    get_next_unread_post
    render 'index'
  end
  
  def search_entry
    render 'shared/dialog'
  end
  
  def show
    @search_mode = (params[:search_mode] ? true : false)
    if @post
      @post_was_unread = @post.mark_read_for_user(@current_user)
      get_next_unread_post
      @admin_cancel = true if @current_user.is_admin? and not @post.authored_by?(@current_user)
    else
      @not_found = true
    end
  end
  
  def new
    @new_post = Post.new(:newsgroup => @newsgroup)
    if @post
      @new_post.subject = 'Re: ' + @post.subject.sub(/^Re: ?/, '')
      @new_post.body = @post.quoted_body
    end
    render 'shared/dialog'
  end
  
  def create
    post_newsgroups = []
    @sync_error = nil
  
    if params[:post][:subject].blank?
      form_error "You must enter a subject line for your post." and return
    end
    
    newsgroup = @newsgroups.where_posting_allowed.find_by_name(params[:post][:newsgroup])
    if newsgroup.nil?
      form_error "The specified newsgroup is either nonexistent or read-only." and return
    end
    post_newsgroups << newsgroup
    
    if params[:crosspost_to] and params[:crosspost_to] != ''
      crosspost_to = @newsgroups.where_posting_allowed.find_by_name(params[:crosspost_to])
      if crosspost_to.nil?
        form_error "The specified cross-post newsgroup is either nonexistent or read-only." and return
      elsif crosspost_to == newsgroup
        form_error "The specified cross-post newsgroup is the same as the primary newsgroup." and return
      end
      post_newsgroups << crosspost_to
    end
    
    # TODO: Generalize the concept of "extra cross-post newsgroups" as a configuration option
    if params[:crosspost_sysadmin]
      n = @newsgroups.where_posting_allowed.find_by_name('csh.lists.sysadmin')
      if post_newsgroups.include?(n)
        form_error "You specified 'also to csh.lists.sysadmin', but that newsgroup is already selected." and return
      end
      post_newsgroups << n
    end
    
    if params[:crosspost_alumni]
      n = @newsgroups.where_posting_allowed.find_by_name('csh.lists.alumni')
      if post_newsgroups.include?(n)
        form_error "You specified 'also to csh.lists.alumni', but that newsgroup is already selected." and return
      end
      post_newsgroups << n
    end
    
    reply_newsgroup = reply_post = nil
    if params[:post][:reply_newsgroup]
      reply_newsgroup = Newsgroup.find_by_name(params[:post][:reply_newsgroup])
      reply_post = Post.where(:newsgroup => params[:post][:reply_newsgroup],
        :number => params[:post][:reply_number]).first
      if reply_post.nil?
        form_error "The post you are trying to reply to doesn't exist; it may have been canceled. Try refreshing the newsgroup." and return
      end
    end
    
    post_string = Post.build_message(
      :user => @current_user,
      :newsgroups => post_newsgroups.map(&:name),
      :subject => params[:post][:subject],
      :body => params[:post][:body],
      :reply_post => reply_post
    )
    
    new_message_id = nil
    begin
      Net::NNTP.start(NEWS_SERVER) do |nntp|
        new_message_id = nntp.post(post_string)[1][/<.*?>/]
      end
    rescue
      form_error 'Error: ' + $!.message and return
    end
    
    begin
      Net::NNTP.start(NEWS_SERVER) do |nntp|
        post_newsgroups.each{ |n| Newsgroup.sync_group!(nntp, n.name, n.status) }
      end
    rescue
      @sync_error = "Your post was accepted by the news server, but an error occurred while attempting to sync the newsgroup it was posted to. This may be a transient issue: Wait a couple minutes and manually refresh the newsgroup, and you should see your post.\n\nThe exact error was: #{$!.message}"
    end
    
    @new_post = Post.find_by_message_id(new_message_id)
    if not @new_post
      @sync_error = "Your post was accepted by the news server, but doesn't appear to actually exist; it may have been held for moderation or silently discarded (though neither of these should ever happen on CSH news). Wait a couple minutes and manually refresh the newsgroup to make sure this isn't a glitch in WebNews."
    end
  end
  
  def destroy
    if @post.nil?
      form_error "The post you are trying to cancel doesn't exist; it may have already been canceled. Try manually refreshing the newsgroup." and return
    end
    
    if not @post.newsgroup.posting_allowed?
      form_error "The newsgroup containing the post you are trying to cancel is read-only. Posts in read-only newsgroups cannot be canceled." and return
    end
    
    if not @post.authored_by?(@current_user) and not @current_user.is_admin?
      form_error "You are not the author of this post; you cannot cancel it without admin privileges." and return
    end
    
    begin
      Net::NNTP.start(NEWS_SERVER) do |nntp|
        nntp.post(@post.build_cancel_message(@current_user, params[:reason]))
      end
    rescue
      form_error 'Error: ' + $!.message and return
    end
    
    begin
      Net::NNTP.start(NEWS_SERVER) do |nntp|
        @post.all_newsgroups.each{ |n| Newsgroup.sync_group!(nntp, n.name, n.status) }
        Newsgroup.sync_group!(nntp, 'control.cancel', 'n')
      end
    rescue
      @sync_error = "Your cancel was accepted by the news server, but an error occurred while attempting to sync the local post database. This may be a transient issue: Wait a couple minutes and manually refresh the newsgroup, and the post should be gone.\n\nThe exact error was: #{$!.message}"
    end
  end
  
  def destroy_confirm
    @admin_cancel = !@post.authored_by?(@current_user)
    render 'shared/dialog'
  end
  
  def edit_sticky
    render 'shared/dialog'
  end
  
  def update_sticky
    if not @current_user.is_admin?
      form_error "You cannot sticky or unsticky posts without admin privileges." and return
    end
    
    if @post.nil?
      form_error "The post you are trying to sticky doesn't exist; it may have been canceled. Try manually refreshing the newsgroup." and return
    end
    
    if params[:do_sticky]
      t = Chronic.parse(params[:sticky_until])
      if t.nil?
        form_error "Unable to parse \"#{params[:sticky_until]}\"." and return
      end
      sticky_until = t - t.sec - ((((t.min + 15) % 30) - 15) * 1.minute)
      if sticky_until < Time.now
        form_error "You must enter a time that is in the future, when rounded to the nearest half-hour." and return
      end
      @post.in_all_newsgroups.each do |post|
        post.update_attributes(:sticky_user => @current_user, :sticky_until => sticky_until)
      end
    else
      @post.in_all_newsgroups.each do |post|
        post.update_attributes(:sticky_until => nil)
      end
    end
  end
  
  private
    
    def set_list_layout_and_offset
      if params[:from_older] or params[:from_newer]
        @full_layout = false
        @from_older = Time.parse(params[:from_older]) rescue nil
        @from_newer = Time.parse(params[:from_newer]) rescue nil
      else
        @full_layout = true
      end
    end
    
    def build_search_conditions
      conditions = []
      values = []
      error_text = nil
      
      if @newsgroup
        conditions << 'newsgroup = ?'
        values << @newsgroup.name
      end
      
      if not params[:keywords].blank?
        begin
          phrases = Shellwords.split(params[:keywords])
          keyword_conditions = []
          keyword_values = []
          exclude_conditions = []
          exclude_values = []
          
          phrases.each do |phrase|
            if phrase[0] == '-'
              exclude_conditions << 'subject like ?'
              exclude_values << '%' + phrase[1..-1] + '%'
              if not params[:subject_only]
                exclude_conditions << 'body like ?'
                exclude_values << '%' + phrase[1..-1] + '%'
              end
            else
              keyword_conditions << 'subject like ?'
              keyword_values << '%' + phrase + '%'
              if not params[:subject_only]
                keyword_conditions << 'body like ?'
                keyword_values << '%' + phrase + '%'
              end
            end
          end
          
          conditions << '(' + 
            '(' + keyword_conditions.join(' or ') + ')' + (
              exclude_conditions.empty? ?
                '' : ' and not (' + exclude_conditions.join(' or ') + ')'
            ) + ')'
          values += keyword_values + exclude_values
        rescue
          error_text = "Keywords field has unbalanced quotes."
        end
      end
      
      if not params[:author].blank?
        conditions << 'author like ?'
        values << '%' + params[:author] + '%'
      end
      
      if not params[:date_from].blank?
        date_from = params[:date_from]
        date_from = 'January 1, ' + date_from if date_from[/^\d{4}$/]
        date_from = Chronic.parse(date_from)
        if not date_from
          error_text = "Unable to parse \"#{params[:date_from]}\"."
        else
          conditions << 'date > ?'
          values << date_from
        end
      end
      if not params[:date_to].blank?
        date_to = params[:date_to]
        date_to = 'January 1, ' + (date_to.to_i + 1).to_s if date_to[/^\d{4}$/]
        date_to = Chronic.parse(date_to)
        if not date_to
          error_text = "Unable to parse \"#{params[:date_to]}\"."
        else
          conditions << 'date < ?'
          values << date_to
        end
      end
      
      return conditions, values, error_text
    end
end
