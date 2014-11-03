# == Schema Information
#
# Table name: posts
#
#  id                    :integer          not null, primary key
#  subject               :text
#  author_raw            :text
#  created_at            :datetime
#  message_id            :text
#  had_attachments       :boolean
#  sticky_user_id        :integer
#  sticky_expires_at     :datetime
#  headers               :text
#  body                  :text
#  is_dethreaded         :boolean
#  followup_newsgroup_id :integer
#  ancestry              :text
#  author_email          :text
#  author_name           :text
#
# Indexes
#
#  index_posts_on_ancestry               (ancestry)
#  index_posts_on_author_email           (author_email)
#  index_posts_on_author_name            (author_name)
#  index_posts_on_author_raw             (author_raw)
#  index_posts_on_created_at             (created_at)
#  index_posts_on_followup_newsgroup_id  (followup_newsgroup_id)
#  index_posts_on_message_id             (message_id) UNIQUE
#  index_posts_on_sticky_expires_at      (sticky_expires_at)
#  index_posts_on_sticky_user_id         (sticky_user_id)
#

class Post < ActiveRecord::Base
  belongs_to :sticky_user, class_name: User

  with_options dependent: :destroy do |assoc|
    assoc.has_many :postings
    assoc.has_many :unread_post_entries
    assoc.has_many :starred_post_entries
  end

  has_many :newsgroups, through: :postings
  belongs_to :followup_newsgroup, class_name: Newsgroup
  has_many :unread_users, through: :unread_post_entries, source: :user
  has_many :starred_users, through: :starred_post_entries, source: :user

  has_ancestry orphan_strategy: :adopt
  before_destroy :mark_children_dethreaded

  validates! :author_raw, :headers, :message_id, :subject, presence: true
  validates! :message_id, uniqueness: true
  validates! :postings, length: { minimum: 1 }

  def self.with_top_level_postings
    includes(:postings).where(postings: { top_level: true })
  end

  def self.with_postings_in_newsgroups(newsgroup_ids)
    includes(:postings).where(postings: { newsgroup_id: newsgroup_ids })
  end

  def root_in(newsgroup)
    path.includes(:postings).where(postings: { newsgroup_id: newsgroup.id }).first
  end

  def primary_posting
    followup_newsgroup_id? ? postings.find_by(newsgroup_id: followup_newsgroup_id) : postings.first
  end

  def primary_newsgroup
    followup_newsgroup_id? ? followup_newsgroup : newsgroups.first
  end

  def author_username
    author_email.split('@')[0] if author_email
  end

  def author_is_local?
    !author_email['@' + LOCAL_DOMAIN].nil? if author_email
  end

  def first_line
    sigless_body.each_line do |line|
      line.chomp!
      if line[/[[:word:]]/] and not (
          line.blank? or line[/^>/] or
          line[/(wrote|writes):$/] or line[/^In article/] or
          line[/^On.*\d{4}.*:/] or line[/wrote in message/] or
          line[/news:.*\.\.\.$/] or line[/^\W*snip\W*$/])
        first = line.sub(/ +$/, '')
        first = first.rstrip + '...' if first[/\w\n/]
        return first.rstrip
      end
    end
    return subject
  end

  def quoted_body(start = 0, length = 0)
    author_name + " wrote:\n\n" + if body.blank?
      subject
    else
      if length > 0
        body[start, length]
      elsif sigless_body.blank?
        subject
      else
        sigless_body
      end
    end.split("\n").map{ |line| '>' + line }.join("\n") + "\n\n"
  end

  def sigless_body
    return body.                               # Things to strip:
      sub(/(.*)\n-- ?\n.*/m, '\\1').           # The line '--' or '-- ' and all following text ("standard" sig)
      sub(/\n\n[-~].*[[:alpha:]].*\n*\z/, ''). # Non-blank final lines starting with [-~] and containing a letter
      rstrip
  end

  def self.sticky
    where.not(sticky_expires_at: nil).where('posts.sticky_expires_at > ?', Time.now)
  end

  def crossposted?
    postings.size > 1
  end

  def orphaned?
    is_dethreaded && root?
  end

  def exists_in_followup_newsgroup?
    postings.exists?(newsgroup_id: followup_newsgroup_id)
  end

  def unread_count_in_thread_for_user(user)
    user.unread_post_entries.where(post_id: root.subtree_ids).count
  end

  def newsgroup_thread_tree(newsgroup:, user:, flatten: false, as_json: false, root: true)
    tree = { post: (as_json ? self.as_json(with_user: user) : self) }
    tree[:children] = if flatten
      if root
        descendants.order(:created_at).map{ |p| p.newsgroup_thread_tree(root: false, newsgroup: newsgroup, user: user, flatten: flatten, as_json: as_json) }
      else
        []
      end
    else
      children.order(:created_at).joins(:postings).where(postings: { newsgroup_id: newsgroup.id }).
        map{ |p| p.newsgroup_thread_tree(newsgroup: newsgroup, user: user, flatten: flatten, as_json: as_json) }
    end
    tree.merge(as_json ? {} : {
      unread: self.unread_for_user?(user),
      personal_level: self.personal_level_for_user(user)
    })
  end

  def authored_by?(user)
    author_name == user.real_name or author_email == user.email
  end

  def user_in_thread?(user)
    return true if authored_by?(user)
    root.subtree.any?{ |post| post.authored_by?(user) }
  end

  def self.starred_by_user(user)
    joins(:starred_post_entries).where(starred_post_entries: { user_id: user.id })
  end

  def starred_by_user?(user)
    user.starred_post_entries.exists?(post_id: id)
  end

  def self.unread_for_user(user)
    joins(:unread_post_entries).where(unread_post_entries: { user_id: user.id })
  end

  def unread_for_user?(user)
    !unread_class_for_user(user).nil?
  end

  def unread_class_for_user(user)
    entry = user.unread_post_entries.find_by_post_id(self)
    if entry
      if entry.user_created
        :manual
      else
        :auto
      end
    else
      nil
    end
  end

  def mark_read_for_user(user)
    entry = unread_post_entries.find_by(user_id: user.id)
    if entry.present?
      entry.destroy!
      true
    else
      false
    end
  end

  def mark_unread_for_user(user, user_created = false)
    UnreadPostEntry.create!(
      user: user,
      post: self,
      personal_level: personal_level_for_user(user),
      user_created: user_created
    )
  end

  def thread_unread_for_user?(user)
    return true if unread_for_user?(user)
    root.subtree.any?{ |post| post.unread_for_user?(user) }
  end

  def personal_level_for_user(user)
    case
      when authored_by?(user) then PERSONAL_CODES[:mine]
      when parent_id.present? && parent.authored_by?(user) then PERSONAL_CODES[:mine_reply]
      when root_id.present? && root.user_in_thread?(user) then PERSONAL_CODES[:mine_in_thread]
      else 0
    end
  end

  def unread_personal_class_for_user(user)
    PERSONAL_CLASSES[user.unread_posts.merge(root.subtree).maximum(:personal_level).to_i]
  end

  private

  def mark_children_dethreaded
    children.update_all(is_dethreaded: true)
  end
end
