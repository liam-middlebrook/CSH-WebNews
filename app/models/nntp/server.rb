module NNTP
  class Server
    include Singleton

    def self.method_missing(method_name, *arguments)
      self.instance.send(method_name, *arguments)
    end

    def newsgroups
      nntp.list[1].map(&:split).map{ |fields| NewsgroupLine.new(*fields) }
    end

    def message_ids(newsgroup_names = [])
      wildmat = newsgroup_names.any? ? newsgroup_names.join(',') : '*'
      nntp.newnews(wildmat, '19700101', '000000')[1].uniq.map{ |message_id| message_id[1..-2] }
    end

    def article(message_id)
      # nntp-lib calls sprintf with this parameter internally, so any percent
      # signs in the Message-ID must be doubled
      nntp.article("<#{message_id.sub('%', '%%')}>")[1].join("\n")
    end

    private

    def nntp
      @nntp ||= Net::NNTP.start(NEWS_SERVER)
    end

    NewsgroupLine = Struct.new(:name, :high, :low, :status)
  end
end
