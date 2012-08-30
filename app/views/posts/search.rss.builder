xml.instruct! :xml, :version => '1.0'
xml.rss :version => '2.0' do
  xml.channel do
    xml.title 'WebNews Search Feed'
    xml.link root_url
    xml.pubDate @posts_older.first[:post].date.to_s(:rfc822) if not @posts_older.empty?
    xml.description 'RSS version of the WebNews search API'
    xml.ttl 1
    
    for thread in @posts_older
      post = thread[:post]
      xml.item do
        xml.title post.subject
        xml.author (post.author_email ? "#{post.author_email} (#{post.author_name})" : post.author_name)
        xml.description { xml.cdata! simple_format(post.body) }
        xml.pubDate post.date.to_s(:rfc822)
        xml.link root_url + '#!' + post_path(post.newsgroup.name, post.number)
        xml.guid root_url + '#!' + post_path(post.newsgroup.name, post.number)
      end 
    end 
  end 
end 
