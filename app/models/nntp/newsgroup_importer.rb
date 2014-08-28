module NNTP
  class NewsgroupImporter
    def initialize(quiet: false)
      @quiet = quiet
    end

    def sync_all!
      print 'Waiting for sync lock... ' if $in_rake

      Flag.with_news_sync_lock(full_sync: true) do
        puts 'OK' if $in_rake

        groups_to_destroy = Newsgroup.pluck(:name) - Server.newsgroup_names
        puts "Deleting #{groups_to_destroy.size} newsgroups.\n\n" if $in_rake
        Newsgroup.where(name: groups_to_destroy).destroy_all

        Server.newsgroups.each do |remote_newsgroup|
          puts remote_newsgroup.name if $in_rake

          newsgroup = Newsgroup.where(name: remote_newsgroup.name).first_or_initialize
          newsgroup.update!(status: remote_newsgroup.status)

          sync_one(newsgroup)
        end
      end
    end

    def sync!(newsgroups)
      Flag.with_news_sync_lock do
        Array(newsgroups).each{ |newsgroup| sync_one(newsgroup) }
      end
    end

    private

    def sync_one(newsgroup)
      Flag.with_news_sync_lock do
        local_numbers = Post.where(newsgroup_name: newsgroup.name).pluck(:number)
        remote_numbers = Server.article_numbers(newsgroup.name)
        numbers_to_destroy = local_numbers - remote_numbers
        numbers_to_import = remote_numbers - local_numbers

        puts "Deleting #{numbers_to_destroy.size} posts." if $in_rake
        numbers_to_destroy.each do |number|
          Post.where(newsgroup_name: newsgroup.name, number: number).first.destroy
        end

        importer = PostImporter.new(newsgroup: newsgroup, quiet: @quiet)

        puts "Importing #{numbers_to_import.size} posts." if $in_rake
        numbers_to_import.each do |number|
          importer.import!(
            number: number,
            article: Server.article(newsgroup.name, number)
          )
          print '.' if $in_rake
        end

        puts if $in_rake
      end
    end
  end
end
