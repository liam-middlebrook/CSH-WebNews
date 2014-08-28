module NNTP
  class PostImporter
    def initialize(newsgroup:, quiet: false)
      @newsgroup, @quiet = newsgroup, quiet
    end

    def import!(number:, article:)
      post = create_post_from_article(number, article)
      process_subscriptions(post) unless @quiet
      post
    end

    private

    def create_post_from_article(number, article)
      mail = Mail.new(article)

      headers = mail.header.to_s
      if mail.multipart?
        headers << "X-WebNews-Text-Part-Headers-Follow: true\n"
        headers << mail.text_part.header.to_s
      end

      date = DATE_HEADERS.map{ |h| mail.header[h] }.compact.first.to_s.to_datetime
      threading_data = guess_threading_for_message(mail, date)

      message = mail.multipart? ? mail.text_part : mail
      message = FlowedFormat.decode_message(message)

      Post.create!(
        newsgroup: @newsgroup,
        number: number,
        subject: utf8_encode(mail.subject),
        author: utf8_encode(mail.header['From'].to_s),
        date: date,
        message_id: "<#{mail.message_id}>",
        parent_id: threading_data[:parent_id],
        thread_id: threading_data[:thread_id],
        stripped: mail.has_attachments?,
        headers: headers,
        body: utf8_encode(message.body.to_s)
      )
    end

    def process_subscriptions(post)
      User.active.each do |user|
        if not post.authored_by?(user)
          personal_level = PERSONAL_CODES[post.personal_class_for_user(user)]
          subscription = user.subscriptions.for(@newsgroup) || user.default_subscription
          unread_level = subscription.unread_level || user.default_subscription.unread_level
          email_level = subscription.email_level || user.default_subscription.email_level

          if personal_level >= unread_level
            UnreadPostEntry.create!(user: user, newsgroup: @newsgroup, post: post, personal_level: personal_level)
          end

          if personal_level >= email_level
            Mailer.post_notification(post, user).deliver
          end
        end
      end
    end

    def guess_threading_for_message(mail, date)
      guess_threading_from_references(mail.references) ||
        guess_threading_from_subject_and_date(mail.subject, date) ||
        { parent_id: '', thread_id: "<#{mail.message_id}>" }
    end

    def guess_threading_from_references(references)
      if references.present?
        references = Array(references).map{ |id| "<#{id}>" }
        possible_parent_id = references[-1]
        possible_thread_id = references[0]
        possible_parent = @newsgroup.posts.find_by(message_id: possible_parent_id)

        if possible_parent.present?
          { parent_id: possible_parent.message_id, thread_id: possible_parent.thread_id }
        elsif Post.where(message_id: possible_parent_id).exists?
          # OK to create a new thread for this post
        elsif @newsgroup.posts.where(message_id: possible_thread_id).exists?
          { parent_id: possible_thread_id, thread_id: possible_thread_id }
        end
      end
    end

    def guess_threading_from_subject_and_date(subject, date)
      if subject =~ /Re:/i
        possible_thread_parent = @newsgroup.posts.thread_parents
          .where('date < ? AND date > ?', date, date - 3.months)
          .where(
            'subject = ? OR subject = ? OR subject = ?',
            subject, subject.sub(/^Re: ?/i, ''), subject.sub(/^Re: ?(\[.+\] )?/i, '')
          )
          .order(:date).first

        if possible_thread_parent.present?
          possible_thread_id = possible_thread_parent.message_id
          { parent_id: possible_thread_id, thread_id: possible_thread_id }
        end
      end
    end

    def utf8_encode(text)
      text.encode('UTF-8', invalid: :replace, undef: :replace)
    end

    DATE_HEADERS = ['Injection-Date', 'NNTP-Posting-Date', 'Date']
  end
end
