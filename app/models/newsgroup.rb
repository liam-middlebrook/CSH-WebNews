class Newsgroup < ActiveRecord::Base
  has_many :unread_post_entries, dependent: :destroy
  has_many :posts, foreign_key: :newsgroup_name, primary_key: :name, dependent: :destroy
  has_many :subscriptions, foreign_key: :newsgroup_name, primary_key: :name, dependent: :destroy

  default_scope -> { order(:name) }

  def as_json(options = {})
    if options[:for_user]
      unread = unread_for_user(options[:for_user])
      super(except: :id).merge(
        unread_count: unread[:count],
        unread_class: unread[:personal_class],
        newest_date: posts.order(:date).last.try(:date)
      )
    else
      super(except: :id)
    end
  end

  def self.cancel
    find_by!(name: 'control.cancel')
  end

  def control?
    true if name[/^control\./]
  end

  def posting_allowed?
    status == 'y'
  end

  def self.where_posting_allowed
    where(status: 'y')
  end

  def unread_for_user(user)
    personal_class = nil
    count = unread_post_entries.where(user_id: user.id).count
    max_level = unread_post_entries.where(user_id: user.id).maximum(:personal_level)
    personal_class = PERSONAL_CLASSES[max_level] if max_level
    return { count: count, personal_class: personal_class }
  end
end
