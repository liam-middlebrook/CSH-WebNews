require 'net/nntp'
$in_rake = true

namespace :webnews do
  desc "Delete and re-import all newsgroups, clearing unread and starred post data"
  task :reload => :environment do
    Newsgroup.reload_all!
  end

  desc "Sync all newsgroups, adding unread post data for any new posts"
  task :sync => :environment do
    Newsgroup.sync_all!
  end

  desc "Remove unread post entries for users considered 'inactive'"
  task :clean_unread => :environment do
    User.clean_unread!
  end

  desc "Email post digests for users with digest subscriptions"
  task :send_digests => :environment do
    Subscription.send_digests!
  end
end
