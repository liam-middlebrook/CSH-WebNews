xml.instruct! :xml, :version => '1.0'
xml.rss :version => '2.0' do
  xml.channel do
    xml.title 'WebNews Search Feed'
    xml.link root_url + '#!' + search_path(@search_params)
    xml.pubDate @posts_older.first[:post].date.to_s(:rfc822) if not @posts_older.empty?
    xml.description 'RSS version of the WebNews search API'
    xml.ttl 1

    for thread in @posts_older
      post = thread[:post]
      xml.item do
        xml.category post.primary_newsgroup.name
        xml.title post.subject
        xml.author(if post.author_name == post.author_email
          post.author_name
        else
          "#{post.author_email} (#{post.author_name})"
        end)
        xml.description { xml.cdata! simple_format(post.body) }
        xml.pubDate post.date.to_s(:rfc822)
        xml.link root_url + '#!' + post_path(post.primary_newsgroup.name, post.primary_posting.number)
        xml.guid root_url + '#!' + post_path(post.primary_newsgroup.name, post.primary_posting.number)
      end
    end
  end
end
