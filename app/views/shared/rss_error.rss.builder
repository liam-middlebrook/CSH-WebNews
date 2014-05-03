xml.instruct! :xml, :version => '1.0'
xml.rss :version => '2.0' do
  xml.channel do
    xml.title 'WebNews Search Feed'
    xml.link root_url
    xml.description 'RSS version of the WebNews search API'
    xml.item do
      xml.title "Error: #{@error_id}"
      xml.description @error_details
    end
  end
end
