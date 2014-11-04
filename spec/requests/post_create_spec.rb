require 'rails_helper'

RSpec.describe 'Post create' do
  it 'submits a new post to the news server' do
    newsgroups = create_list(:newsgroup, 2, status: 'y')
    allow_nntp_server.to receive(:post).and_return('dummy@post.here')
    allow_nntp_server.to receive(:message_ids).and_return(['dummy@post.here'])
    allow_nntp_server.to receive(:article).and_return(<<-ARTICLE.strip_heredoc
      Subject: test post
      From: #{oauth_user.real_name} <#{oauth_user.email}>
      Message-ID: dummy@post.here
      Newsgroups: #{newsgroups.map(&:name).join(',')}
      Followup-To: #{newsgroups.first.name}
      Xref: #{newsgroups.first.name}:119 #{newsgroups.last.name}:151

      here is my post everypeople
    ARTICLE
    )

    post(posts_path, {
      subject: 'test post',
      body: 'here is my post everypeople',
      newsgroup_ids: newsgroups.map(&:id).join(','),
      followup_newsgroup_id: newsgroups.first.id
    })

    expect(response.status).to be 201
    expect(response.headers['Location']).to eq post_url(Post.last.id)
  end

  it 'returns error information when given invalid parameters' do
    post(posts_path, {
      newsgroup_ids: create(:newsgroup, status: 'y').id,
      parent_id: 1
    })

    expect(response.status).to be 422
    expect(response_json).to eq({
      errors: {
        parent_id: ['specifies a nonexistent post'],
        subject: ["can't be blank"]
      }
    })
  end

  it 'returns an appropriate status when the post is accepted but not synced' do
    allow_nntp_server.to receive(:post).and_return('dummy@post.here')
    allow_nntp_server.to receive(:message_ids).and_return([])

    post(posts_path, {
      subject: 'test post',
      newsgroup_ids: create(:newsgroup, status: 'y').id
    })

    expect(response.status).to be 202
    expect(response.headers['Location']).to_not be_present
  end
end
