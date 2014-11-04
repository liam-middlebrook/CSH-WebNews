require 'rails_helper'

RSpec.describe 'Post destroy' do
  it 'cancels a post' do
    cancel = create(:newsgroup, name: 'control.cancel')
    newsgroup = create(:newsgroup, status: 'y')
    post = create(:post, newsgroups: [newsgroup], author_email: oauth_user.email)
    allow_nntp_server.to receive(:post).and_return('dummy@cancel.here')
    allow_nntp_server.to receive(:message_ids).and_return(['dummy@cancel.here'])
    allow_nntp_server.to receive(:article).and_return(<<-ARTICLE.strip_heredoc
      Subject: cancel <#{post.message_id}>
      From: #{oauth_user.real_name} <#{oauth_user.email}>
      Message-ID: dummy@cancel.here
      Control: cancel <#{post.message_id}>
      Newsgroups: #{newsgroup.name}
      Xref: news.example control.cancel:135

      this post done got canceled
    ARTICLE
    )

    delete post_path(post)

    expect(response.status).to be 204
    expect(response.headers['Location']).to eq post_url(cancel.posts.last)
  end

  it 'returns error information when the post cannot be canceled' do
    newsgroup = create(:newsgroup, status: 'y')
    post = create(:post, newsgroups: [newsgroup], author_email: oauth_user.email)
    create(:post, parent: post)

    delete post_path(post)

    expect(response.status).to be 422
    expect(response_json).to eq({
      errors: {
        post: ['has one or more replies']
      }
    })
  end
end
