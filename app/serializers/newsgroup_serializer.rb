class NewsgroupSerializer < ActiveModel::Serializer
  attributes :id, :name, :posting_allowed,
    :unread_count, :max_unread_level, :newest_post_at, :oldest_post_at

  def max_unread_level
    scoped_unread_post_entries.maximum(:personal_level)
  end

  # FIXME: Remove `in_time_zone` if the below PR ever gets merged
  # https://github.com/rails/rails/pull/13711

  def newest_post_at
    object.posts.maximum(:created_at).try(:in_time_zone)
  end

  def oldest_post_at
    object.posts.minimum(:created_at).try(:in_time_zone)
  end

  # FIXME: Next version of AMS should auto-strip the question mark
  # https://github.com/rails-api/active_model_serializers/pull/662

  def posting_allowed
    object.posting_allowed?
  end

  def unread_count
    scoped_unread_post_entries.count
  end

  private

  def scoped_unread_post_entries
    object.unread_post_entries.merge(scope.unread_post_entries)
  end
end
