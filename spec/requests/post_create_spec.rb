require 'rails_helper'

RSpec.describe 'Post create' do
  it 'submits a new post to the news server' do
    newsgroups = create_list(:newsgroup, 2, status: 'y')
    allow_nntp_server.to receive(:post).and_return('dummy@post.here')
    allow_nntp_server.to receive(:message_ids).and_return(['dummy@post.here'])
    allow_nntp_server.to receive(:article).and_return(<<-ARTICLE.strip_heredoc
      Subject: test post
      From: #{oauth_user.display_name} <#{oauth_user.email}>
      Message-ID: dummy@post.here
      Newsgroups: #{newsgroups.map(&:id).join(',')}
      Followup-To: #{newsgroups.first.id}
      Xref: news.example #{newsgroups.first.id}:19 #{newsgroups.last.id}:51

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
    expect(response.headers['Location']).to eq post_url('dummy@post.here')
  end

  it 'submits a reply to an existing news post' do
    newsgroup = create(:newsgroup, status: 'y')
    post = create(:post, id: 'dummy@post.here', newsgroups: [newsgroup])
    allow_nntp_server.to receive(:post).and_return('dummy@reply.here')
    allow_nntp_server.to receive(:message_ids).and_return(['dummy@reply.here'])
    allow_nntp_server.to receive(:article).and_return(<<-ARTICLE.strip_heredoc
      Subject: test reply
      From: #{oauth_user.display_name} <#{oauth_user.email}>
      References: dummy@post.here
      Message-ID: dummy@reply.here
      Newsgroups: #{newsgroup.id}
      Xref: news.example #{newsgroup.id}:42

      here is my reply everypeople
    ARTICLE
    )

    post(posts_path, {
      subject: 'test reply',
      body: 'here is my reply everypeople',
      newsgroup_ids: newsgroup.id,
      parent_id: post.id
    })

    expect(response.status).to be 201
    expect(response.headers['Location']).to eq post_url('dummy@reply.here')
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

  it 'returns error information when NNTP transmission fails' do
    allow_nntp_server.to receive(:post).and_raise(Net::NNTPFatalError, 'ouchy!')

    post(posts_path, {
      subject: 'test post',
      newsgroup_ids: create(:newsgroup, status: 'y').id
    })

    expect(response.status).to be 422
    expect(response_json).to eq({ errors: { nntp: ['ouchy!'] } })
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
