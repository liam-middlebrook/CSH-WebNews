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
    
    quote_depth = 0
    post.body.each_line do |line|
      depth_change = (line[/^>[> ]*/] || '').gsub(/\s/, '').length - quote_depth
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
    
    return html_body
  end

end
