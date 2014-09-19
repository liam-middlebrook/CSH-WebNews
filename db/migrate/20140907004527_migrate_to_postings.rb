class MigrateToPostings < ActiveRecord::Migration
  class Post < ActiveRecord::Base
  end

  def up
    newsgroup_ids = {}
    Newsgroup.find_each do |newsgroup|
      newsgroup_ids[newsgroup.name] = newsgroup.id
    end
    seen_message_ids = {}
    duplicate_post_ids = []

    say_with_time 'Putting posts in newsgroups...' do
      Post.find_each.with_index do |post, index|
        if seen_message_ids[post.message_id]
          duplicate_post_ids << post.id
        else
          seen_message_ids[post.message_id] = true

          newsgroup_names = if post.headers =~ /^Control: cancel/
            ['control.cancel']
          else
            post.headers[/^Newsgroups: (.*)/i, 1].split(',').map(&:strip)
          end

          newsgroup_names.each do |newsgroup_name|
            post_in_newsgroup = Post.find_by(newsgroup_name: newsgroup_name, message_id: post.message_id)
            unless post_in_newsgroup.nil?
              posting = Posting.new(
                newsgroup_id: newsgroup_ids[newsgroup_name],
                post_id: post.id,
                number: post_in_newsgroup.number
              )
              posting.save!(validate: false)
            end
          end
        end

        say("#{index} done", true) if index % 1000 == 0 && index > 0
      end

      Post.destroy(duplicate_post_ids)
    end

    change_table :posts do |t|
      t.remove :newsgroup_name
      t.remove :number
    end
  end

  def down
    change_table :posts do |t|
      t.text :newsgroup_name
      t.integer :number
      t.index :newsgroup_name
      t.index [:newsgroup_name, :number]
    end

    Post.find_each do |post|
      if Posting.where(post_id: post.id).count > 1
        postings = Posting.where(post_id: post.id).to_a
        post.update!(newsgroup_name: Newsgroup.find(postings[0].newsgroup_id).name, number: postings[0].number)
        postings[1..-1].each do |posting|
          Post.create!(post.attributes.except('id').merge(newsgroup_name: Newsgroup.find(posting.newsgroup_id).name, number: posting.number))
        end
      end
    end

    Posting.delete_all
  end
end
