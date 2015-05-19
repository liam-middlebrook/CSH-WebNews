# == Schema Information
#
# Table name: posts
#
#  id                    :integer          not null, primary key
#  subject               :text
#  author_raw            :text
#  created_at            :datetime
#  message_id            :text
#  had_attachments       :boolean          default(FALSE)
#  sticky_user_id        :integer
#  sticky_expires_at     :datetime
#  headers               :text
#  body                  :text
#  is_dethreaded         :boolean          default(FALSE)
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
    assoc.has_many :stars
  end

  has_many :newsgroups, through: :postings
  belongs_to :followup_newsgroup, class_name: Newsgroup
  has_many :unread_users, through: :unread_post_entries, source: :user
  has_many :starred_users, through: :stars, source: :user

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

  def self.since(datetime)
    where('posts.created_at >= ?', datetime)
  end

  def self.until(datetime)
    where('posts.created_at <= ?', datetime)
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

  def authored_by?(user)
    author_email == user.email
  end

  def user_in_thread?(user)
    return true if authored_by?(user)
    root.subtree.any?{ |post| post.authored_by?(user) }
  end

  def self.starred_by(user)
    joins(:stars).where(stars: { user_id: user.id })
  end

  def starred_by?(user)
    user.stars.exists?(post_id: id)
  end

  def self.unread_for(user, min_personal_level: 0)
    joins(:unread_post_entries).where(unread_post_entries: {
      user_id: user.id,
      personal_level: (min_personal_level..(PERSONAL_LEVELS.size - 1)).to_a
    })
  end

  def unread_for?(user)
    !unread_class_for(user).nil?
  end

  def unread_class_for(user)
    entry = user.unread_post_entries.find_by_post_id(self)
    if entry.present?
      if entry.user_created
        :manual
      else
        :auto
      end
    else
      nil
    end
  end

  def personal_level_for(user)
    case
      when authored_by?(user) then PERSONAL_LEVELS[:mine]
      when parent_id.present? && parent.authored_by?(user) then PERSONAL_LEVELS[:reply]
      when root_id.present? && root.user_in_thread?(user) then PERSONAL_LEVELS[:in_thread]
      else 0
    end
  end

  private

  def mark_children_dethreaded
    children.update_all(is_dethreaded: true)
  end
end
