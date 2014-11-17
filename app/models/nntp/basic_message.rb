module NNTP
  class BasicMessage
    include ActiveAttr::Model
    include ActiveModel::ForbiddenAttributesProtection

    attr_reader :was_accepted

    attribute :posting_host, type: String, default: ''
    attribute :user_agent, type: String
    attribute :user, type: Object

    validates! :user, :user_agent, presence: true

    def transmit
      return if was_accepted
      return unless valid?

      message_id = begin
        Server.post(to_mail.to_s)
      rescue Net::NNTPError
        errors.add(:nntp, $!.message)
        nil
      end

      if message_id.present?
        @was_accepted = true

        begin
          NNTP::NewsgroupImporter.new.sync!(newsgroups)
        rescue
          ExceptionNotifier.notify_exception($!)
        end

        Post.find_by(message_id: message_id)
      end
    end

    private

    def to_mail
      mail = Mail.new(from: from_line)

      mail.header['User-Agent'] = 'CSH WebNews'
      mail.header['X-WebNews-User-Agent'] = user_agent

      if posting_host.present?
        mail.header['X-WebNews-Posting-Host'] = posting_host
      end

      mail
    end

    def from_line
      address = Mail::Address.new
      address.display_name = user.display_name
      address.address = user.email
      address.to_s
    end

    def newsgroups
      raise 'must be implemented in subclass'
    end
  end
end
