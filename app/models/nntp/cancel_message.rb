module NNTP
  class CancelMessage < BasicMessage
    attr_accessor :post, :reason

    private

    def to_mail
      mail = super
      mail.subject = mail.header['Control'] = "cancel <#{post.message_id}>"
      mail.header['Newsgroups'] = post_message.header['Newsgroups']

      mail.body = body
      mail = FlowedFormat.encode_message(mail)

      mail
    end

    def post_message
      @post_message ||= Mail.new(post.headers)
    end

    def body
      body_lines = ["This message was canceled by #{user.real_name}:", '']

      body_lines += INCLUDE_HEADERS.map do |header|
        "  #{header}: #{post_message.header[header]}"
      end

      if reason.present?
        body_lines += ['', "The reason given was: #{reason}"]
      end

      body_lines.join("\n")
    end

    INCLUDE_HEADERS = ['From', 'Subject', 'Date', 'Newsgroups', 'Message-ID']
  end
end
