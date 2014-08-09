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
  task :reload => :environment do
    with_notifier{ Newsgroup.reload_all! }
  end

  desc "Sync all newsgroups, adding unread post data for any new posts"
  task :sync => :environment do
    if File.exists?('tmp/maintenance.txt') and not ENV['FORCE']
      puts 'Skipping sync because maintenance mode is on (use FORCE=true to override)'
    else
      with_notifier{ Newsgroup.sync_all! }
    end
  end

  desc "Remove unread post entries for users considered 'inactive'"
  task :clean_unread => :environment do
    with_notifier{ User.clean_unread! }
  end

  desc "Email post digests for users with digest subscriptions"
  task :send_digests => :environment do
    with_notifier{ Subscription.send_digests! }
  end
end
