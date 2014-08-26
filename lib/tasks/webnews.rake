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
  desc "Delete and re-import all newsgroups, clearing unread and starred post data"
  task reload: :environment do
    with_notifier{ Newsgroup.reload_all! }
  end

  desc "Sync all newsgroups, adding unread post data for any new posts"
  task sync: :environment do
    if Flag.maintenance_mode? && ENV['FORCE'].blank?
      puts 'Skipping sync because maintenance mode is on.'
      puts 'Use "rake webnews:sync FORCE=true" to override.'
      puts
    else
      with_notifier{ Newsgroup.sync_all! }
    end
  end

  desc "Remove unread post entries for users considered 'inactive'"
  task clean_unread: :environment do
    with_notifier{ User.clean_unread! }
  end

  desc "Email post digests for users with digest subscriptions"
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
