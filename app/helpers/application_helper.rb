module ApplicationHelper

  def next_unread_href
    if @next_unread_post
      '#!' + post_path(@next_unread_post.newsgroup.name, @next_unread_post.number)
    else
      '#'
    end
  end
  
  def home_page_title
    if @current_user and @current_user.unread_count > 0
      "(#{@current_user.unread_count}) CSH WebNews"
    else
      'CSH WebNews'
    end
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
      pre_body.gsub!(/((\a|\n)(>#{more_quotes}.*(\n|\z))+)/,
        '\\2' + "#{MARK_STRING}3" + '\\1' + "#{MARK_STRING}4\n")
    end
    
    # This structure tends to cause problems when the replacements are done
    if pre_body[/#{MARK_STRING}3.*#{MARK_STRING}1.*#{MARK_STRING}4/m]
      return post_html_body(post, false)
    end
    
    html_body = html_escape(pre_body)
    
    if quote_collapse
      quoted = html_body[/#{MARK_STRING}1\n.*#{MARK_STRING}2/m].andand.gsub(/#{MARK_STRING}\d\n/, '')
      # If the text that would be collapsed is trivially short, forget it
      if quoted and quoted.length <= 800 and quoted.scan("\n").length <= 8
        return post_html_body(post, false)
      else
        html_body.gsub!("#{MARK_STRING}1\n",
          '<a id="show_quote_button" href="#" class="showquote toggle" data-selector="#post_view .fullquote"
            data-text="Hide quoted text">Show quoted text</a>' + "\n" + '<div class="fullquote">'
        )
        html_body.gsub!(/#{MARK_STRING}2(\n|\z)/, '</div>')
      end
    end
    html_body.gsub!("#{MARK_STRING}3\n", "<blockquote>")
    html_body.gsub!("#{MARK_STRING}4\n", "</blockquote>")
    
    # Definitely shouldn't have any leftover MARK_STRING at this point
    if quote_collapse and html_body[MARK_STRING]
      return post_html_body(post, false)
    end
    
    html_body = auto_link(html_body, :link => :urls, :sanitize => false)
    
    return html_body
  end

end
