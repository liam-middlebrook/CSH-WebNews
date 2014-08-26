class Newsgroup < ActiveRecord::Base
  has_many :unread_post_entries, dependent: :destroy
  has_many :posts, foreign_key: :newsgroup_name, primary_key: :name, dependent: :destroy
  has_many :subscriptions, foreign_key: :newsgroup_name, primary_key: :name, dependent: :destroy

  default_scope -> { order(:name) }

  def as_json(options = {})
    if options[:for_user]
      unread = unread_for_user(options[:for_user])
      super(except: :id).merge(
        unread_count: unread[:count],
        unread_class: unread[:personal_class],
        newest_date: posts.order(:date).last.try(:date)
      )
    else
      super(except: :id)
    end
  end

  def control?
    true if name[/^control\./]
  end

  def posting_allowed?
    status == 'y'
  end

  def self.where_posting_allowed
    where(status: 'y')
  end

  def unread_for_user(user)
    personal_class = nil
    count = unread_post_entries.where(user_id: user.id).count
    max_level = unread_post_entries.where(user_id: user.id).maximum(:personal_level)
    personal_class = PERSONAL_CLASSES[max_level] if max_level
    return { count: count, personal_class: personal_class }
  end

  def self.reimport!(post)
    Flag.with_news_sync_lock do
      head = body = nil
      Net::NNTP.start(NEWS_SERVER) do |nntp|
        nntp.group(post.newsgroup_name)
        head = nntp.head(post.number)[1].join("\n")
        body = nntp.body(post.number)[1].join("\n")
      end
      entries = post.unread_post_entries + post.starred_post_entries
      post.delete # Shhh, don't run the destroy handlers
      new_post = Post.import!(post.newsgroup, post.number, head, body)
      entries.each do |entry|
        entry.update_attributes(post: new_post)
      end
    end
  end

  def self.sync_group!(nntp, name, status, mark_unread: true)
    Flag.with_news_sync_lock do
      if Newsgroup.where(name: name).exists?
        newsgroup = Newsgroup.where(name: name).first
        newsgroup.update_attributes(status: status)
      else
        newsgroup = Newsgroup.create!(name: name, status: status)
      end

      puts newsgroup.name if $in_rake
      my_posts = Post.where(newsgroup_name: newsgroup.name).pluck(:number)
      news_posts = nntp.listgroup(newsgroup.name)[1].map(&:to_i)
      to_delete = my_posts - news_posts
      to_import = news_posts - my_posts

      puts "Deleting #{to_delete.size} posts." if $in_rake
      to_delete.each do |number|
        Post.where(newsgroup_name: newsgroup.name, number: number).first.destroy
      end

      puts "Importing #{to_import.size} posts." if $in_rake
      to_import.each do |number|
        head = nntp.head(number)[1].join("\n")
        body = nntp.body(number)[1].join("\n")
        post = Post.import!(newsgroup, number, head, body)
        if mark_unread
          User.active.each do |user|
            if not post.authored_by?(user)
              personal_level = PERSONAL_CODES[post.personal_class_for_user(user)]
              subscription = user.subscriptions.for(newsgroup) || user.default_subscription
              unread_level = subscription.unread_level || user.default_subscription.unread_level
              email_level = subscription.email_level || user.default_subscription.email_level

              if personal_level >= unread_level
                UnreadPostEntry.create!(user: user, newsgroup: newsgroup, post: post, personal_level: personal_level)
              end

              if personal_level >= email_level
                Mailer.post_notification(post, user).deliver
              end
            end
          end
        end
        print '.' if $in_rake
      end
      puts if $in_rake
    end
  end

  def self.sync_all!(mark_unread: true)
    print 'Waiting for sync lock... ' if $in_rake

    Flag.with_news_sync_lock(full_sync: true) do
      print "OK\n\n" if $in_rake

      Net::NNTP.start(NEWS_SERVER) do |nntp|
        my_groups = Newsgroup.select(:name).collect(&:name)
        news_groups = nntp.list[1].collect{ |line| line.split[0] }
        (my_groups - news_groups).each{ |name| Newsgroup.find_by_name(name).destroy }

        nntp.list[1].each do |line|
          s = line.split
          sync_group!(nntp, s[0], s[3], mark_unread: mark_unread)
        end
      end
    end
  end
end
