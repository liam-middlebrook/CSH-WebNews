class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_frame_options, :set_request_format
  before_filter :check_maintenance, :check_auth, :get_or_create_user

  private

    def check_auth
      if not Newsgroup.select(true).first
        @no_script = true
        render 'shared/no_groups'
      elsif not request.env[ENV_USERNAME]
        if not User.select(true).first and not params[:no_user_override]
          if DEVELOPMENT_MODE
            User.create!(username: 'nobody', real_name: 'Testing User')
          else
            @no_script = true
            render 'shared/no_users'
          end
        elsif not DEVELOPMENT_MODE and not params[:api_key]
          respond_to do |wants|
            wants.html { render 'shared/authenticate', layout: false }
            wants.js { render 'shared/unauthenticated' }
            wants.any { generic_error :unauthorized, 'api_key_missing',
              "API access requires a key to be provided in the 'api_key' parameter" }
          end
        end
      end
    end

    def check_maintenance
      if Flag.maintenance_mode?
        @no_script = true
        @reason = Flag.maintenance_reason

        respond_to do |wants|
          wants.any(:html, :js) { render 'shared/maintenance' }
          wants.any {
            generic_error :service_unavailable,
              'under_maintenance',
              'WebNews is down for maintenance: ' + Flag.maintenance_reason
          }
        end
      end
    end

    def get_or_create_user
      if params[:api_key]
        @current_user = User.find_by_api_key(params[:api_key])
        if @current_user.nil?
          generic_error :unauthorized, 'api_key_invalid',
            "The API key '#{params[:api_key]}' does not match any known user"
        elsif not params[:api_agent]
          generic_error :unauthorized, 'api_agent_missing',
            "API access requires an app name to be provided in the 'api_agent' parameter"
        else
          @api_access = true
          @api_rss = request.format.rss?
          @current_user.update_attributes(api_data: {
            last_access: Time.now,
            last_agent: params[:api_agent],
            last_ip: request.remote_ip
          })
          if params[:thread_mode]
            if ['normal', 'flat', 'hybrid'].include?(params[:thread_mode])
              @current_user.preferences[:thread_mode] = params[:thread_mode].to_sym
            else
              generic_error :bad_request, 'thread_mode_invalid',
                "The thread_mode value '#{params[:thread_mode]}' is not one of ['normal', 'flat', 'hybrid']"
            end
          end
        end
      else # Non-API access, may create the user
        @current_user = DEVELOPMENT_MODE ? User.first :
          User.find_by_username(request.env[ENV_USERNAME])

        if @current_user.nil?
          if request.format.html?
            @current_user = User.create!(
              username: request.env[ENV_USERNAME],
              real_name: request.env[ENV_REALNAME]
            )
            @new_user = true
          else
            generic_error :forbidden, 'user_not_created',
              'This user has no account and must visit the main WebNews site to create one'
          end
        elsif @current_user.inactive?
          if request.format.html?
            @old_user = true
          else
            generic_error :forbidden, 'user_inactive',
              'This account has been marked inactive and must be reactivated through the main WebNews site'
          end
        end
      end

      if @current_user
        @current_user.touch
        Time.zone = @current_user.time_zone
        Chronic.time_class = Time.zone
      end
    end

    def get_newsgroups_for_nav
      @newsgroups = Newsgroup.all
      @newsgroups_writable = @newsgroups.select{ |n| n.posting_allowed? }
      @newsgroups_readonly = @newsgroups.select{ |n| not n.posting_allowed? and not n.control? }
      @newsgroups_control = @newsgroups.select{ |n| n.control? }
    end

    def get_newsgroups_for_search
      @newsgroups = Newsgroup.unscoped.order('status DESC, name')
    end

    def get_newsgroups_for_posting
      @newsgroups = Newsgroup.where_posting_allowed
    end

    def get_newsgroup
      name = params[:newsgroup] || params[:post].try(:fetch, :newsgroup, nil)
      if not name.blank?
        @newsgroup = Newsgroup.find_by_name(name)
        if @api_access and not @newsgroup
          generic_error :not_found, 'newsgroup_not_found', "Newsgroup '#{name}' does not exist"
        end
      end
    end

    def get_post
      number = params[:number] || params[:from_number]
      if not params[:newsgroup].blank? and not number.blank?
        @post = Post.where(number: number, newsgroup_name: params[:newsgroup]).first
        if @api_access and not @post
          generic_error :not_found, 'post_not_found',
            "Post number '#{number}' in newsgroup '#{params[:newsgroup]}' does not exist"
        end
      elsif number and @api_access
        generic_error :bad_request, 'newsgroup_missing',
          "Both the 'newsgroup' and 'number' parameters are required to uniquely identify a post"
      end
    end

    def get_next_unread_post
      unread_order = "CASE unread_post_entries.user_created WHEN #{Post.sanitize(true)} THEN 2 ELSE 1 END"
      standard_order = 'newsgroup_name, date'

      if @post and @current_user.thread_mode == :normal
        order = "#{unread_order},
        CASE newsgroup_name WHEN #{Post.sanitize(@post.newsgroup_name)} THEN 1 ELSE 2 END,
        CASE thread_id WHEN #{Post.sanitize(@post.thread_id)} THEN 1 ELSE 2 END,
        CASE parent_id WHEN #{Post.sanitize(@post.message_id)} THEN 1 ELSE 2 END,
        CASE parent_id WHEN #{Post.sanitize(@post.parent_id)} THEN 1 ELSE 2 END, #{standard_order}"
      elsif @post and @current_user.thread_mode == :hybrid
        order = "#{unread_order},
        CASE newsgroup_name WHEN #{Post.sanitize(@post.newsgroup_name)} THEN 1 ELSE 2 END,
        CASE thread_id WHEN #{Post.sanitize(@post.thread_id)} THEN 1 ELSE 2 END, #{standard_order}"
      elsif @newsgroup
        order = "#{unread_order},
          CASE newsgroup_name WHEN #{Post.sanitize(@newsgroup_name)} THEN 1 ELSE 2 END, #{standard_order}"
      else
        order = "#{unread_order}, #{standard_order}"
      end

      @next_unread_post = @current_user.unread_posts.order(order).first
    end

    def get_last_sync_time
      @last_sync_time = Flag.last_full_news_sync_at
      if @last_sync_time < 2.minutes.ago
        @sync_warning = "Last sync with the news server was #{view_context.time_ago_in_words(@last_sync_time)} ago."
      end
    end

    def form_error(details)
      @error_details = details
      render 'shared/form_error'
    end

    def rss_error(status, id, details)
      @error_id, @error_details = id, details
      render 'shared/rss_error', status: status
    end

    def json_error(status, id, details)
      allow_cross_origin_access
      render status: status, json: json_error_object(id, details)
    end

    def generic_error(status, id, details)
      respond_to do |wants|
        wants.js { form_error(details) }
        wants.rss { rss_error(status, id, details) }
        wants.json { json_error(status, id, details) }
      end
    end

    def json_error_object(id, details)
      {
        error: {
          id: id,
          details: details
        }
      }
    end

    def json_sync_warning
      if @sync_warning
        {
          warning: {
            id: 'sync_outdated',
            last_sync: @last_sync_time,
            details: @sync_warning
          }
        }
      else
        {}
      end
    end

    def log_exception(exception)
      logger.error(exception.message)
      logger.error(exception.backtrace.join("\n"))
    end

    def remote_host
      Resolv.getname(request.remote_ip) rescue request.remote_ip
    end

    def prevent_api_access
      head :forbidden if @api_access
    end

    def allow_cross_origin_access
      request_origin = request.headers['Origin']
      if request_origin =~ /\Ahttps.*#{LOCAL_DOMAIN}\Z/
        headers['Access-Control-Allow-Origin'] = request_origin
        headers['Access-Control-Allow-Methods'] = 'GET'
        headers['Access-Control-Allow-Credentials'] = 'true'
      end
    end

    def set_frame_options
      headers['X-Frame-Options'] = 'DENY'
    end

    def set_request_format
      # JSON request detection doesn't seem to work if Accept contains multiple content types
      if request.headers['Accept'].present? && request.headers['Accept'] =~ /application\/json/
        request.format = :json
        @api_access = true
      end
    end
end
