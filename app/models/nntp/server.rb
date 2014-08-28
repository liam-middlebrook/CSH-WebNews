module NNTP
  class Server
    include Singleton

    def self.method_missing(method_name, *arguments)
      self.instance.send(method_name, *arguments)
    end

    def newsgroups
      nntp.list[1].map(&:split).map{ |fields| NewsgroupLine.new(*fields) }
    end

    def newsgroup_names
      nntp.list[1].map{ |line| line.split[0] }
    end

    def article_numbers(newsgroup)
      nntp.listgroup(newsgroup)[1].map(&:to_i)
    end

    def article(newsgroup, number)
      nntp.group(newsgroup) unless @current_newsgroup == newsgroup
      @current_newsgroup = newsgroup

      nntp.article(number)[1].join("\n")
    end

    private

    def nntp
      @nntp ||= Net::NNTP.start(NEWS_SERVER)
    end

    NewsgroupLine = Struct.new(:name, :high, :low, :status)
  end
end
