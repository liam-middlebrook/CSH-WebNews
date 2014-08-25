class Post < ActiveRecord::Base
  belongs_to :newsgroup, foreign_key: :newsgroup_name, primary_key: :name
  belongs_to :sticky_user, class_name: 'User'
  has_many :unread_post_entries, dependent: :destroy
  has_many :starred_post_entries, dependent: :destroy
  has_many :unread_users, through: :unread_post_entries, source: :user
  has_many :starred_users, through: :starred_post_entries, source: :user

  before_destroy :kill_parent_id

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
        json[:parent] = original_parent ?
          original_parent.as_json(minimal: true) :
          parent.as_json(minimal: true)
        json[:thread_parent] = thread_parent.as_json(minimal: true) if not thread_parent == self
        json[:reparented] = reparented? && !orphaned?
        json[:orphaned] = orphaned? && !original_parent
        json[:followup_to] = followup_newsgroup.name if followup_newsgroup
        json[:cross_posts] = (in_all_newsgroups - [self]).map{ |post| post.as_json(minimal: true) }
      end
    end

    json[:newsgroup] = newsgroup_name

    if options[:with_user]
      json.merge!(
        starred: starred_by_user?(options[:with_user]),
        unread_class: unread_class_for_user(options[:with_user]),
        personal_class: personal_class_for_user(options[:with_user])
      )
    end

    return json
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

  def crossposted?(quick = false)
    if quick
      all_newsgroup_names.length > 1
    else
      in_all_newsgroups.length > 1
    end
  end

  def reparented?
    parent_id != original_parent_id
  end

  def orphaned?
    reparented? and parent_id == ''
  end

  def followup_newsgroup
    Newsgroup.find_by_name(headers[/^Followup-To: (.*)/i, 1])
  end

  def exists_in_followup_newsgroup?
    !in_newsgroup(followup_newsgroup).nil?
  end

  def all_newsgroups
    all_newsgroup_names.map{ |name| Newsgroup.find_by_name(name) }.reject(&:nil?)
  end

  def all_newsgroup_names
    if headers =~ /^Control: cancel/
      ['control.cancel']
    else
      headers[/^Newsgroups: (.*)/i, 1].split(',').map(&:strip)
    end
  end

  def in_newsgroup(newsgroup)
    newsgroup.posts.find_by_message_id(message_id)
  end

  def in_all_newsgroups
    all_newsgroups.
      map{ |newsgroup| in_newsgroup(newsgroup) }.
      reject(&:nil?)
  end

  def parent
    parent_id == '' ? nil : Post.where(message_id: parent_id, newsgroup_name: newsgroup_name).first
  end

  def children
    Post.where(parent_id: message_id, newsgroup_name: newsgroup_name)
  end

  def thread_parent
    message_id == thread_id ? self : all_in_thread.order('date').first
  end

  def self.thread_parents
    where('message_id = thread_id')
  end

  def all_in_thread
    Post.where(thread_id: thread_id, newsgroup_name: newsgroup_name).order('date')
  end

  def post_count_in_thread
    all_in_thread.count
  end

  def unread_count_in_thread_for_user(user)
    user.unread_post_entries.where(post_id: all_in_thread.pluck(:id)).count
  end

  def thread_tree_for_user(user, flatten = false, as_json = false, all_posts = nil)
    all_posts ||= all_in_thread.order('date').to_a
    {
      post: (as_json ? self.as_json(with_user: user) : self),
      children: if flatten
        all_posts.reject{ |p| p == self }.map{ |p| {
          post: (as_json ? p.as_json(with_user: user) : p), children: []
        }.merge(as_json ? {} : {
          unread: p.unread_for_user?(user),
          personal_class: p.personal_class_for_user(user)
        })}
      else
        all_posts.
          select{ |p| p.parent_id == self.message_id }.
          map{ |p| p.thread_tree_for_user(user, flatten, as_json, all_posts) }
      end
    }.merge(as_json ? {} : {
      unread: self.unread_for_user?(user),
      personal_class: self.personal_class_for_user(user)
    })
  end

  def original_parent_id
    headers[/^References: (.*)/i, 1].to_s.split.map{ |r| r[/<.*>/] }[-1] || ''
  end

  def original_parent
    Post.where(message_id: original_parent_id).first
  end

  def authored_by?(user)
    author_name == user.real_name or author_email == user.email
  end

  def user_in_thread?(user)
    return true if authored_by?(user)
    return all_in_thread.any?{ |post| post.authored_by?(user) }
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
    was_unread = false
    in_all_newsgroups.each do |post|
      entry = post.unread_post_entries.where(user_id: user.id).first
      if entry
        entry.destroy
        was_unread = true
      end
    end
    return was_unread
  end

  def mark_unread_for_user(user, user_created)
    UnreadPostEntry.create!(
      user: user,
      newsgroup: newsgroup,
      post: self,
      personal_level: PERSONAL_CODES[personal_class_for_user(user)],
      user_created: user_created
    )
  end

  def thread_unread_for_user?(user)
    return true if unread_for_user?(user)
    return all_in_thread.any?{ |post| post.unread_for_user?(user) }
  end

  def personal_class_for_user(user, check_thread = true)
    case
      when authored_by?(user) then :mine
      when parent && parent.authored_by?(user) then :mine_reply
      when check_thread && thread_parent.user_in_thread?(user) then :mine_in_thread
    end
  end

  def unread_personal_class_for_user(user)
    PERSONAL_CLASSES[user.unread_posts.where(thread_id: thread_id).maximum(:personal_level).to_i]
  end

  def kill_parent_id
    # Sub-optimal, should re-parent to next reference up the chain
    # (but posts getting canceled when they already have replies is rare)
    Post.where(parent_id: message_id).each do |post|
      post.update_attributes(parent_id: '', thread_id: post.message_id)
    end
  end

  def self.import!(newsgroup, number, headers, body)
    stripped = false
    headers = unwrap_headers(headers)
    headers.encode!('US-ASCII', invalid: :replace, undef: :replace)

    part_headers, body = multipart_decode(headers, body)
    stripped = true if headers[/^Content-Type:.*mixed/i]

    body = body.unpack('m')[0] if part_headers[/^Content-Transfer-Encoding: base64/i]
    body = body.unpack('M')[0] if part_headers[/^Content-Transfer-Encoding: quoted-printable/i]

    if part_headers[/^Content-Type:.*(X-|unknown)/i]
      body.encode!('UTF-8', 'US-ASCII', invalid: :replace, undef: :replace)
    elsif part_headers[/^Content-Type:.*charset/i]
      begin
        body.encode!('UTF-8', part_headers[/^Content-Type:.*charset="?([^"]+?)"?(;|$)/i, 1],
          invalid: :replace, undef: :replace)
      rescue
        body.encode!('UTF-8', 'US-ASCII', invalid: :replace, undef: :replace)
      end
    else
      begin
        body.encode!('UTF-8', 'US-ASCII') # RFC 2045 Section 5.2
      rescue
        begin
          body.encode!('UTF-8', 'Windows-1252')
        rescue
          body.encode!('UTF-8', 'US-ASCII', invalid: :replace, undef: :replace)
        end
      end
    end

    if body[/^begin(-base64)? \d{3} /]
      body.gsub!(/^begin \d{3} .*?\nend\n/m, '')
      body.gsub!(/^begin-base64 \d{3} .*?\n====\n/m, '')
      stripped = true
    end

    body = flowed_decode(body) if part_headers[/^Content-Type:.*format="?flowed"?/i]

    body.rstrip!

    date = Time.parse(
      headers[/^Injection-Date: (.*)/i, 1] ||
      headers[/^NNTP-Posting-Date: (.*)/i, 1] ||
      headers[/^Date: (.*)/i, 1]
    )
    author = header_decode(headers[/^From: (.*)/i, 1])
    subject = header_decode(headers[/^Subject: (.*)/i, 1])
    message_id = headers[/^Message-ID: (.*)/i, 1]
    references = headers[/^References: (.*)/i, 1].to_s.split.map{ |r| r[/<.*>/] }

    parent_id = references[-1] || ''
    thread_id = message_id
    possible_thread_id = references[0] || ''

    parent = where(message_id: parent_id, newsgroup_name: newsgroup.name).first

    if parent
      thread_id = parent.thread_id
    elsif parent_id != '' and where(message_id: parent_id).exists?
      parent_id = ''
    elsif possible_thread_id != '' and where(message_id: possible_thread_id, newsgroup_name: newsgroup.name).exists?
      parent_id = thread_id = possible_thread_id
    elsif subject =~ /Re:/i
      possible_thread_parent = where(
        '(subject = ? or subject = ? or subject = ?) and newsgroup_name = ? and parent_id = ? and date < ? and date > ?',
        subject, subject.sub(/^Re: ?/i, ''), subject.sub(/^Re: ?(\[.+\] )?/i, ''), newsgroup.name, '', date, date - 3.months
      ).order('date').first

      if possible_thread_parent
        parent_id = thread_id = possible_thread_parent.message_id
      else
        parent_id = ''
      end
    else
      parent_id = ''
    end

    create!(newsgroup: newsgroup,
            number: number,
            subject: subject,
            author: author,
            date: date,
            message_id: message_id,
            parent_id: parent_id,
            thread_id: thread_id,
            stripped: stripped,
            headers: headers,
            body: body)
  end

  # See RFC 3676 for "format=flowed" spec

  def self.flowed_decode(body)
    new_body_lines = []
    body.each_line do |line|
      line.chomp!
      quotes = line[/^>+/]
      line.sub!(/^>+/, '')
      line.sub!(/^ /, '')
      if line != '-- ' and
          new_body_lines.length > 0 and
          !new_body_lines[-1][/^-- $/] and
          new_body_lines[-1][/ $/] and
          quotes == new_body_lines[-1][/^>+/]
        new_body_lines[-1] << line
      else
        new_body_lines << quotes.to_s + line
      end
    end
    return new_body_lines.join("\n")
  end

  def self.multipart_decode(headers, body)
    if headers[/^Content-Type: multipart/i]
      boundary = Regexp.escape(headers[/^Content-Type:.*boundary ?= ?"?([^"]+?)"?(;|$)/i, 1])
      match = /.*?#{boundary}\n(.*?)\n\n(.*?)\n(--)?#{boundary}/m.match(body)
      part_headers = unwrap_headers(match[1])
      part_body = match[2]
      return multipart_decode(part_headers, part_body)
    else
      return headers, body
    end
  end

  def self.unwrap_headers(headers)
    headers.gsub(/\n( |\t)/, ' ').gsub(/\t/, ' ')
  end

  def self.header_decode(header)
    begin
      Rfc2047.decode(header)
    rescue Rfc2047::Unparseable
      header
    end
  end
end
