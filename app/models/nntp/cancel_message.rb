module NNTP
  class CancelMessage < BasicMessage
    attribute :post, type: Object
    attribute :reason, type: String, default: ''

    validates! :post, presence: true
    validate :newsgroups_must_allow_posting
    validate :post_must_have_no_children
    validate :user_must_be_author_or_admin

    private

    def to_mail
      mail = super
      mail.subject = mail.header['Control'] = "cancel <#{post.message_id}>"
      mail.header['Newsgroups'] = post_message.header['Newsgroups']

      mail.body = body
      mail = FlowedFormat.encode_message(mail)

      mail
    end

    def newsgroups
      @newsgroups ||= post.newsgroups + [Newsgroup.cancel]
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

    def newsgroups_must_allow_posting
      if post.newsgroups.size != post.newsgroups.where_posting_allowed.size
        errors.add(:post, 'is posted to one or more read-only newsgroups')
      end
    end

    def post_must_have_no_children
      if post.children.any?
        errors.add(:post, 'has one or more replies')
      end
    end

    def user_must_be_author_or_admin
      if !post.authored_by?(user) && !user.admin?
        errors.add(:post, 'is from another user and requires admin privileges to cancel')
      end
    end

    INCLUDE_HEADERS = ['From', 'Subject', 'Date', 'Newsgroups', 'Message-ID']
  end
end
