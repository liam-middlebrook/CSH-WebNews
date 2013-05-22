class Mailer < ActionMailer::Base
  helper ApplicationHelper
  
  def post_notification(post, user)
    @post = post
    
    author_action = if post.personal_class_for_user(user) == :mine_reply
      "replied to your post \"#{post.parent.subject}\""
    elsif post.thread_parent == post
      "started a new thread \"#{post.subject}\""
    else
      "posted in thread \"#{post.thread_parent.subject}\""
    end
    
    mail(:to => user.email, :subject => "[#{post.newsgroup_name}] #{post.author_name} #{author_action}")
  end
  
  def posts_digest(user, start_at, end_at, target_email_type)
    @posts = []
    
    Newsgroup.find_each do |newsgroup|
      subscription = user.subscriptions.for(newsgroup) || user.default_subscription
      email_type = subscription.email_type.presence || user.default_subscription.email_type
      
      if email_type == target_email_type
        email_level = subscription.email_level || user.default_subscription.email_level
        
        newsgroup.posts.where("date >= ? AND date <= ?", start_at, end_at).find_each do |post|
          personal_level = PERSONAL_CODES[post.personal_class_for_user(user)]
          
          if personal_level >= email_level and not post.authored_by?(user)
            @posts << post
          end
        end
      end
    end
    
    title = case target_email_type
      when 'daily_digest' then "Daily digest for #{start_at.strftime(DATE_ONLY_FORMAT)}"
      when 'weekly_digest' then "Weekly digest for week of #{start_at.strftime(DATE_ONLY_FORMAT)}"
      when 'monthly_digest' then "Monthly digest for #{start_at.strftime(MONTH_ONLY_FORMAT)}"
    end
    
    if @posts.any?
      mail(:to => user.email, :subject => "#{title} (#{@posts.count} new posts)")
    end
  end
end
