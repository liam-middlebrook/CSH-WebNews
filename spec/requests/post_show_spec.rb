require 'rails_helper'

RSpec.describe 'Post show' do
  it 'retrieves info about a single post' do
    sticky_user = create(:user)
    newsgroup = create(:newsgroup)
    root = create(:post, newsgroups: [newsgroup])
    parent = create(:post,
      parent: root,
      newsgroups: [newsgroup],
      author: "#{oauth_user.real_name} <#{oauth_user.username}>"
    )
    post = create(:post,
      parent: parent,
      newsgroups: [newsgroup],
      author: 'Test User <tester@example.com>',
      sticky_user: sticky_user,
      sticky_until: 1.week.from_now,
      stripped: true,
      dethreaded: false
    )
    first_posting = post.postings.first
    second_posting = create(:posting, post: post)
    post.update!(followup_newsgroup_id: second_posting.newsgroup_id)
    post.mark_unread_for_user(oauth_user)
    create(:starred_post_entry, post: post, user: oauth_user)

    get post_path(post)

    expect(response).to be_successful
    expect(response_json.keys).to eq [:post]
    expect(response_json[:post]).to eq({
      created_at: post.date.iso8601,
      subject: post.subject,
      message_id: post.message_id,
      headers: post.headers,
      body: post.body,
      author: {
        name: 'Test User',
        email: 'tester@example.com',
        raw: 'Test User <tester@example.com>'
      },
      stickiness: {
        username: sticky_user.username,
        display_name: sticky_user.real_name,
        expires_at: post.sticky_until.iso8601
      },
      followup_newsgroup_id: post.followup_newsgroup_id,
      postings: [
        {
          newsgroup_id: first_posting.newsgroup_id,
          number: first_posting.number
        },
        {
          newsgroup_id: second_posting.newsgroup_id,
          number: second_posting.number
        }
      ],
      parent_id: parent.id,
      root_id: root.id,
      had_attachments: true,
      is_dethreaded: false,
      personal_level: PERSONAL_CODES[:mine_reply],
      unread_class: 'auto',
      is_starred: true
    })
  end
end
