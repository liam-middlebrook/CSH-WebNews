module ApplicationHelper
  def current_user_stylesheet
    if @current_user.present?
      theme_stylesheet(@current_user.theme)
    else
      theme_stylesheet(:classic)
    end
  end

  def theme_stylesheet(name)
    "theme-#{name}.css"
  end

  def maybe_you(name, capitalize = false)
    if name == @current_user.real_name
      capitalize ? 'You' : 'you'
    else
      name
    end
  end

  def post_hash_url(post)
    root_url + '#!' + post_path(
      post.primary_newsgroup.name, post.primary_posting.number
    )
  end

  def abbrev_newsgroup(newsgroup_name)
    if newsgroup_name =~ /^control/
      newsgroup_name
    else
      newsgroup_name.gsub(/([^.])[^.]*\./, '\\1.')
    end
  end

  def abbrev_newsgroup_html(newsgroup_name)
    html_escape(abbrev_newsgroup(newsgroup_name)).
      sub(/(.*\.)/, '<span class="abbreviated">\\1</span>').html_safe
  end

  def author_line(post)
    post.author_name + if post.author_email != post.author_name
      if post.author_is_local?
        ' (' + post.author_username + ')'
      else
        ' <' + post.author_email + '>' if post.author_email
      end
    else
      ''
    end
  end

  def gravatar_image(email, size)
    email ||= 'nobody@example.com'
    image_tag 'https://secure.gravatar.com/avatar/' +
      Digest::MD5.hexdigest(email.gsub(/\s+/, '').downcase) +
      "?size=#{size}&default=mm&rating=pg",
      alt: '', size: "#{size}x#{size}", class: 'gravatar'
  end

  def next_unread_href
    if @next_unread_post
      '#!' + post_path(
        @next_unread_post.primary_newsgroup.name,
        @next_unread_post.primary_posting.number
      )
    else
      '#'
    end
  end

  def home_page_title
    if @current_user and @current_user.unread_count > 0
      "(#{@current_user.unread_count}) WebNews"
    else
      'WebNews'
    end
  end

  def home_unread_line
    unread = @current_user.unread_count
    unread_thread = @current_user.unread_count_in_thread
    unread_reply = @current_user.unread_count_in_reply

    if unread == 0
      unread_line = 'You have no unread posts.'
    else
      unread_line = "You have <span class=\"unread\">#{pluralize(unread, 'unread post')}</span>"
      if unread_thread + unread_reply > 0
        unread_line += ' ('
        if unread_thread > 0
          unread_line += "<span class=\"mine_in_thread\">#{unread_thread} in threads you've posted in</span>"
          unread_line += ', ' if unread_reply > 0
        end
        if unread_reply > 0
          unread_line += "<span class=\"mine_reply\">#{unread_reply} in reply to your posts</span>"
        end
        unread_line += ')'
      end
      unread_line += '.'
    end

    return unread_line
  end

  def activity_breakout(activity)
    now = Time.now

    stickies = activity.select{ |item| item[:thread_parent].sticky? }
    activity -= stickies

    breakout = {}

    {
      'Today' => ->(item) { item[:newest_post].date > now.beginning_of_day },
      'Yesterday' => ->(item) { item[:newest_post].date > (now - 1.day).beginning_of_day },
      'This Week' => ->(item) { item[:newest_post].date > now.beginning_of_week },
      'Last Week' => ->(item) { item[:newest_post].date > (now - 1.week).beginning_of_week },
      'This Month' => ->(item) { item[:newest_post].date > now.beginning_of_month },
      'Last Month' => ->(item) { true }
    }.each do |heading, proc|
      break if activity.empty?

      items = activity.select(&proc)
      activity -= items

      if items.any?
        if activity.any?
          breakout.merge!({ heading => items })
        else
          if breakout.any?
            breakout.merge!({ 'Earlier' => items })
          else
            breakout.merge!({ 'Recent Activity' => items })
          end
        end
      end
    end

    { 'Stickies' => stickies }.merge(breakout).reject{ |_, items| items.empty? }
  end

  def post_html_body(post, quote_collapse = true)
    pre_body = post.body.dup
    parent = post.parent
    html_body = ''
    quote_collapse &&= parent

    # Warning: Even I barely understand this, and I wrote it. --grantovich

    if quote_collapse and @current_user.thread_mode == :normal
      [parent.body, parent.sigless_body].each do |parent_body|
        regex = '[> ]*' +
          Regexp.escape(parent_body.gsub(/[>\s]+/, MARK_STRING)).gsub(MARK_STRING, '[>\s]+')
        match = pre_body[Regexp.new(regex)]
        next if match.nil?
        pre_body.gsub!(
          Regexp.new('(' + Regexp.escape(match.rstrip) + ')'),
          "#{MARK_STRING}1\n" + '\\1' + "\n#{MARK_STRING}2"
        )
        break if pre_body != post.body
      end
    end

    (1..3).each do |depth|
      more_quotes = ' ?>' * (depth - 1)
      pre_body.gsub!(/(\A|\n)((>#{more_quotes}.*(\n|\z))+)/,
        '\\1' + "#{MARK_STRING}3\n" + '\\2' + "#{MARK_STRING}4\n")
    end

    # This structure tends to cause problems when the replacements are done
    if pre_body[/#{MARK_STRING}3.*#{MARK_STRING}1.*#{MARK_STRING}4/m]
      return post_html_body(post, false)
    end

    html_body = html_escape(pre_body)

    if quote_collapse
      quoted = html_body[/#{MARK_STRING}1\n.*#{MARK_STRING}2/m].try(:gsub, /#{MARK_STRING}\d\n/, '')
      # If the text that would be collapsed is trivially short, forget it
      if quoted and quoted.length <= 800 and quoted.scan("\n").length <= 10
        return post_html_body(post, false)
      else
        if @api_access
          html_body.gsub!("#{MARK_STRING}1\n", '<div class="quoted_text">')
        else
          html_body.gsub!("#{MARK_STRING}1\n",
            '<span id="added_post_text"><a href="#"
              id="show_quote_button" class="smallbutton showquote toggle"
              data-selector="#post_view .fullquote">Quoted text</a>' +
              "\n" + '</span><div class="fullquote">'
          )
        end
        html_body.gsub!(/#{MARK_STRING}2(\n|\z)/, '</div>')
      end
    end
    html_body.gsub!("#{MARK_STRING}3\n", "<blockquote>")
    html_body.gsub!("#{MARK_STRING}4\n", "</blockquote>")

    # Definitely shouldn't have any leftover MARK_STRING at this point
    if quote_collapse and html_body[MARK_STRING]
      return post_html_body(post, false)
    end

    # gsub doesn't work with this regex, unfortunately
    {} while html_body.sub!(
      /(\[\d+\])(?!<\/a>)(.*\n {0,3}\1[^\n]*?(https?:[^\s]+).*?(\n|\z))/m,
      '<a href="\\3">\\1</a>\\2'
    )
    html_body = auto_link(html_body, link: :urls, sanitize: false)

    return html_body
  end
end
