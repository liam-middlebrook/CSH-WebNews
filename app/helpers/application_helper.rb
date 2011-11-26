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
  
  def post_html_body(post)
    html_body = ''
    pre_body = post.body.dup
    parent = post.parent

    if parent and @current_user.thread_mode == :normal
      [parent.body, parent.sigless_body].each do |parent_body|
        regex = '>\s*' + Regexp.escape(parent_body.gsub(/[>\s]+/, MARK_STRING)).gsub(MARK_STRING, '[>\s]+')
        match = pre_body[Regexp.new(regex)]
        next if match.nil?
        pre_body.gsub!(
          Regexp.new('(' + Regexp.escape(match.rstrip) + ')'),
          "#{MARK_STRING}1" + '\\1' + "#{MARK_STRING}2"
        )
        break if pre_body != post.body
      end
    end

    quote_depth = 0
    pre_body.each_line do |line|
      depth_change = (line[/^(#{MARK_STRING}(1|2))?>[> ]*/] || '').
        gsub(/\s|(#{MARK_STRING}(1|2))/, '').length - quote_depth
      line = html_escape(line.chomp)
      if depth_change > 0
        line = ('<blockquote>' * depth_change) + line
      elsif depth_change < 0
        line = ('</blockquote>' * depth_change.abs) + line
      end
      quote_depth += depth_change
      html_body += line + "\n"
    end

    html_body = auto_link(html_body, :link => :urls, :sanitize => false)

    html_body.gsub!("#{MARK_STRING}1",
      '<a href="#" class="showquote" onclick="$(\'#post_view .fullquote\').toggle()">Show quoted text</a>' +
      "\n" + '<div class="fullquote">')
    html_body.gsub!("#{MARK_STRING}2", '</div>')
    html_body.gsub!("</div>\n</blockquote>", "\n</div></blockquote>")
    
    return html_body
  end

end
