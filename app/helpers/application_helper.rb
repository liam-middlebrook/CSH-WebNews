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
    pre_body = post.body.dup
    parent = post.parent
    html_body = ''
    
    # Warning: Even I barely understand this, and I wrote it. --grantovich
    
    if parent and @current_user.thread_mode == :normal
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
    
    html_body = html_escape(pre_body)
    html_body.gsub!("#{MARK_STRING}1\n",
      '<a href="#" class="showquote toggle" data-selector="#post_view .fullquote"
        data-text="Hide quoted text">Show quoted text</a>' + "\n" + '<div class="fullquote">'
    )
    html_body.gsub!(/#{MARK_STRING}2(\n|\z)/, '</div>')
    html_body.gsub!("#{MARK_STRING}3\n", "<blockquote>")
    html_body.gsub!("#{MARK_STRING}4\n", "</blockquote>")
    
    html_body = auto_link(html_body, :link => :urls, :sanitize => false)
    
    return html_body
  end

end
