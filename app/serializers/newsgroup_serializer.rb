class NewsgroupSerializer < ActiveModel::Serializer
  attributes :id, :name, :status, :updated_at,
    :unread_count, :unread_personal_level, :newest_post_at, :oldest_post_at

  def newest_post_at
    object.posts.maximum(:date)
  end

  def oldest_post_at
    object.posts.minimum(:date)
  end

  def unread_count
    scoped_unread_post_entries.count
  end

  def unread_personal_level
    scoped_unread_post_entries.maximum(:personal_level)
  end

  private

  def scoped_unread_post_entries
    object.unread_post_entries.merge(scope.unread_post_entries)
  end
end
