$in_rake = true

def with_notifier
  begin
    yield
  rescue
    ExceptionNotifier.notify_exception($!)
    raise $!
  end
end

namespace :webnews do
  desc 'Sync all newsgroups (QUIET=true to ignore subscriptions)'
  task sync: :environment do
    puts "\nFull sync triggered at #{Time.now}"

    if Flag.maintenance_mode? && ENV['FORCE'].blank?
      puts 'Skipping sync because maintenance mode is on.'
      puts 'Use "rake webnews:sync FORCE=true" to override.'
      puts
    else
      with_notifier do
        NNTP::NewsgroupImporter.new(quiet: ENV['QUIET'].present?).sync_all!
      end
    end
  end

  desc 'Reload all posts in all newsgroups (warning: slow!)'
  task reload: :environment do
    puts "Reloading all #{Post.count} posts..."
    importer = NNTP::PostImporter.new(quiet: true)

    Flag.with_news_sync_lock do
      Post.order(:date).find_each.with_index do |post, index|
        importer.import!(article: NNTP::Server.article(post.message_id), post: post)
        puts "#{index} done" if index % 1000 == 0 && index > 0
      end
    end
  end

  desc 'Mark all posts as read for users considered "inactive"'
  task clean_unread: :environment do
    with_notifier{ User.clean_unread! }
  end

  desc 'Email post digests for users with digest subscriptions'
  task send_digests: :environment do
    with_notifier{ Subscription.send_digests! }
  end

  namespace :maintenance do
    desc 'Turn on maintenance mode'
    task on: :environment do
      if ENV['REASON'].present?
        Flag.maintenance_mode_on!(ENV['REASON'])
      else
        puts 'Usage: rake webnews:maintenance:on REASON="Explanation here."'
      end
    end

    desc 'Turn off maintenance mode'
    task off: :environment do
      Flag.maintenance_mode_off!
    end
  end
end
