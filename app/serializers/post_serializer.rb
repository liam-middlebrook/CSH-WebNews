class PostSerializer < ActiveModel::Serializer
  attributes :id,
    :author,
    :body,
    :created_at,
    :followup_newsgroup_id,
    :headers,
    :is_dethreaded,
    :is_starred,
    :had_attachments,
    :message_id,
    :newsgroup_ids,
    :parent_id,
    :personal_level,
    :root_id,
    :sticky,
    :subject,
    :total_stars,
    :unread_class

  def author
    {
      name: object.author_name,
      email: object.author_email,
      raw: object.author_raw
    }
  end

  def body
    # Convert legacy web client URLs into RFC5538 'news' URIs
    object.body.gsub(%r(https://#{SERVER_NAME}/#!/(\S+)/index)) do
      'news:' + $1
    end.gsub(%r(https://#{SERVER_NAME}/#!/(\S+)/(\d+))) do |match|
      posting = Newsgroup.find_by(name: $1).try(:postings).try(:find_by, number: $2)
      if posting.nil?
        match
      else
        'news:' + posting.post.message_id
      end
    end
  end

  def newsgroup_ids
    object.postings.pluck(:newsgroup_id)
  end

  def is_starred
    object.starred_by?(scope)
  end

  def personal_level
    object.personal_level_for(scope)
  end

  def sticky
    {
      username: object.sticky_user.try(:username),
      display_name: object.sticky_user.try(:display_name),
      expires_at: object.sticky_expires_at
    }
  end

  def total_stars
    object.stars.size
  end

  def unread_class
    object.unread_class_for(scope)
  end
end
