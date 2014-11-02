class PostSerializer < ActiveModel::Serializer
  has_many :postings
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
    :parent_id,
    :personal_level,
    :root_id,
    :stickiness,
    :subject,
    :unread_class

  def created_at
    object.date
  end

  def is_dethreaded
    object.dethreaded
  end

  def had_attachments
    object.stripped
  end

  def author
    {
      name: object.author_name,
      email: object.author_email,
      raw: object.author_raw
    }
  end

  def is_starred
    object.starred_by_user?(scope)
  end

  def personal_level
    object.personal_level_for_user(scope)
  end

  def stickiness
    {
      username: object.sticky_user.try(:username),
      display_name: object.sticky_user.try(:real_name),
      expires_at: object.sticky_until
    }
  end

  def unread_class
    object.unread_class_for_user(scope)
  end
end
