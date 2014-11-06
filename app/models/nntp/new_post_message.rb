module NNTP
  class NewPostMessage < BasicMessage
    attribute :body, type: String, default: ''
    attribute :followup_newsgroup_id, type: Integer
    attribute :newsgroup_ids, type: String, default: ''
    attribute :parent_id, type: Integer, default: nil
    attribute :subject, type: String

    validates :newsgroup_ids, :subject, presence: true
    validate :followup_newsgroup_must_exist
    validate :newsgroups_must_exist_and_allow_posting
    validate :parent_must_exist

    private

    def to_mail
      mail = super
      mail.subject, mail.body = subject, body
      mail = FlowedFormat.encode_message(mail)

      mail.header['Newsgroups'] = newsgroups.pluck(:name).join(',')
      if parsed_newsgroup_ids.size > 1
        mail.header['Followup-To'] = followup_newsgroup.name
      end

      if parent.present?
        # FIXME: Mail 2.6 allows assigning an array of message_ids directly,
        # but Rails 4.1 locks Mail at 2.5 so we have to do this little dance
        # to coax the property into existence
        mail.header['References'] = '<x@x>'
        mail.header['References'].message_ids.delete_at(0)
        mail.header['References'].message_ids.concat(
          (parent_message.header['References'].message_ids rescue []) +
          [parent_message.message_id]
        )
      end

      mail
    end

    def newsgroups
      @newsgroups ||= Newsgroup.where(id: parsed_newsgroup_ids)
    end

    def parsed_newsgroup_ids
      @parsed_newsgroup_ids ||= newsgroup_ids.split(',').map(&:to_i)
    end

    def followup_newsgroup
      @followup_newsgroup ||= Newsgroup.find_by(id: followup_newsgroup_id)
    end

    def parent_message
      @parent_message ||= if parent.present?
        Mail.new(parent.headers)
      end
    end

    def parent
      @parent ||= Post.find_by(id: parent_id)
    end

    def followup_newsgroup_must_exist
      if parsed_newsgroup_ids.size > 1
        if followup_newsgroup_id.blank?
          errors.add(:followup_newsgroup_id, 'must be provided if posting to multiple newsgroups')
        elsif followup_newsgroup.blank?
          errors.add(:followup_newsgroup_id, 'specifies a nonexistent newsgroup')
        end
      end
    end

    def newsgroups_must_exist_and_allow_posting
      if newsgroups.size != parsed_newsgroup_ids.size
        errors.add(:newsgroup_ids, 'specifies one or more nonexistent newsgroups')
      elsif newsgroups.size != newsgroups.where_posting_allowed.size
        errors.add(:newsgroup_ids, 'specifies one or more read-only newsgroups')
      end
    end

    def parent_must_exist
      if parent_id.present? && parent.blank?
        errors.add(:parent_id, 'specifies a nonexistent post')
      end
    end
  end
end