# == Schema Information
#
# Table name: posts
#
#  id                    :integer          not null, primary key
#  subject               :text
#  author                :text
#  date                  :datetime
#  message_id            :text
#  stripped              :boolean
#  sticky_user_id        :integer
#  sticky_until          :datetime
#  headers               :text
#  body                  :text
#  dethreaded            :boolean
#  followup_newsgroup_id :integer
#  ancestry              :text
#
# Indexes
#
#  index_posts_on_ancestry               (ancestry)
#  index_posts_on_date                   (date)
#  index_posts_on_followup_newsgroup_id  (followup_newsgroup_id)
#  index_posts_on_message_id             (message_id) UNIQUE
#  index_posts_on_sticky_until           (sticky_until)
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

  validates! :author, :date, :message_id, :subject, presence: true
  validates! :message_id, uniqueness: true
  validates! :postings, length: { minimum: 1 }

  def as_json(options = {})
    if options[:minimal]
      json = { number: number }
    else
      only = [:number, :subject, :date, :sticky_until]
      only += [:body] if options[:with_all]
      only += [:headers] if options[:with_headers]
      json = super(
        only: only,
        include: { sticky_user: { only: [:username, :real_name] } },
        methods: [:author_name, :author_email]
      )
      if options[:with_all]
        json[:stripped] = stripped
        json[:parent] = parent.as_json(minimal: true)
        json[:thread_parent] = root.as_json(minimal: true) unless root?
        json[:reparented] = dethreaded? && !orphaned?
        json[:orphaned] = orphaned? && !original_parent
        json[:followup_to] = followup_newsgroup.name if followup_newsgroup
        json[:cross_posts] = nil # FIXME: Remove when new API created
      end
    end

    json[:newsgroup] = primary_newsgroup.name

    if options[:with_user]
      json.merge!(
        starred: starred_by_user?(options[:with_user]),
        unread_class: unread_class_for_user(options[:with_user]),
        personal_class: personal_class_for_user(options[:with_user])
      )
    end

    return json
  end

  def self.top_level
    includes(:postings).where(postings: { top_level: true })
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

  def author_name
    candidate = author[/(.*)<.*>/, 1]
    if candidate
      candidate.gsub(/(\A|[^\\])"/, '\\1').gsub('\\"', '"').rstrip
    else
      author[/.* \((.*)\)/, 1] || author
    end
  end

  def author_email
    author[/.*<(.*)>/, 1] || author[/(.*) \(.*\)/, 1] || author[/\S+@\S+\.\S+/]
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
    where('sticky_until is not null and sticky_until > ?', Time.now)
  end

  def sticky?
    !sticky_until.nil? and sticky_until > Time.now
  end

  def crossposted?
    postings.size > 1
  end

  def orphaned?
    dethreaded? && root?
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
        descendants.order(:date).map{ |p| p.newsgroup_thread_tree(root: false, newsgroup: newsgroup, user: user, flatten: flatten, as_json: as_json) }
      else
        []
      end
    else
      children.order(:date).joins(:postings).where(postings: { newsgroup_id: newsgroup.id }).
        map{ |p| p.newsgroup_thread_tree(newsgroup: newsgroup, user: user, flatten: flatten, as_json: as_json) }
    end
    tree.merge(as_json ? {} : {
      unread: self.unread_for_user?(user),
      personal_class: self.personal_class_for_user(user)
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
    starred_users.include?(user)
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

  def mark_unread_for_user(user, user_created)
    UnreadPostEntry.create!(
      user: user,
      post: self,
      personal_level: PERSONAL_CODES[personal_class_for_user(user)],
      user_created: user_created
    )
  end

  def thread_unread_for_user?(user)
    return true if unread_for_user?(user)
    root.subtree.any?{ |post| post.unread_for_user?(user) }
  end

  def personal_class_for_user(user, check_thread = true)
    case
      when authored_by?(user) then :mine
      when parent && parent.authored_by?(user) then :mine_reply
      when check_thread && root.user_in_thread?(user) then :mine_in_thread
    end
  end

  def unread_personal_class_for_user(user)
    PERSONAL_CLASSES[user.unread_posts.merge(root.subtree).maximum(:personal_level).to_i]
  end

  private

  def mark_children_dethreaded
    children.update_all(dethreaded: true)
  end
end
