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
  
  desc "Create a test user for local development, and disable Webauth"
  task :no_auth => :environment do
    User.create!(:username => 'nobody', :real_name => 'Testing User') if not User.any?
    FileUtils.touch('tmp/authdisabled.txt')
  end
end
