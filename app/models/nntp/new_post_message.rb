module NNTP
  class NewPostMessage < BasicMessage
    attr_accessor :body, :newsgroups, :parent_post, :subject

    validates! :subject, presence: true
    validates! :newsgroups, length: { minimum: 1 }

    private

    def to_mail
      mail = super
      mail.subject, mail.body = subject, body
      mail = FlowedFormat.encode_message(mail)

      mail.header['Newsgroups'] = newsgroups.map(&:name).join(',')
      if newsgroups.size > 1
        mail.header['Followup-To'] = newsgroups.first.name
      end

      if parent_post.present?
        # FIXME: Mail 2.6 allows assigning an array of message_ids directly,
        # but Rails 4.1 locks Mail at 2.5 so we have to do this little dance
        # to coax the property into existence
        mail.header['References'] = '<x@x>'
        mail.header['References'].message_ids.delete_at(0)
        mail.header['References'].message_ids.concat(
          (parent_post_message.header['References'].message_ids rescue []) +
          [parent_post_message.message_id]
        )
      end

      mail
    end

    def parent_post_message
      @parent_post_message ||= Mail.new(parent_post.headers)
    end
  end
end
