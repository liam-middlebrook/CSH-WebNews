class Mailer < ActionMailer::Base
  helper ApplicationHelper

  def post_notification(post, user)
    @post = post

    author_action = if post.personal_level_for_user(user) == PERSONAL_CODES[:mine_reply]
      "replied to your post \"#{post.parent.subject}\""
    elsif post.root?
      "posted \"#{post.subject}\""
    else
      "posted in thread \"#{post.root.subject}\""
    end

    # FIXME: This should really be the name of the subscribed newsgroup that
    # actually triggered the notification
    mail(to: user.email, subject: "[#{post.primary_newsgroup.name}] #{post.author_name} #{author_action}")
  end

  def posts_digest(user, start_at, end_at, target_digest_type)
    @posts = []

    Newsgroup.find_each do |newsgroup|
      subscription = user.subscriptions.for(newsgroup) || user.default_subscription
      digest_type = subscription.digest_type.presence || user.default_subscription.digest_type

      if digest_type == target_digest_type
        @posts << newsgroup.posts.where("date >= ? AND date <= ?", start_at, end_at).order(:date)
      end
    end

    title = case target_digest_type
      when 'daily' then "Daily digest for #{start_at.strftime(DATE_ONLY_FORMAT)}"
      when 'weekly' then "Weekly digest for week of #{start_at.strftime(DATE_ONLY_FORMAT)}"
      when 'monthly' then "Monthly digest for #{start_at.strftime(MONTH_ONLY_FORMAT)}"
    end

    if @posts.any?
      mail(to: user.email, subject: "#{title} (#{@posts.count} new posts)")
    end
  end
end
