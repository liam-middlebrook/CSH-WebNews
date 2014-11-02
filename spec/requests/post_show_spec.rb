require 'rails_helper'

RSpec.describe 'Post show' do
  it 'retrieves info about a single post' do
    sticky_user = create(:user)
    root = create(:post)
    parent = create(:post,
      parent: root,
      author_name: oauth_user.real_name,
      author_email: oauth_user.email
    )
    post = create(:post,
      parent: parent,
      sticky_user: sticky_user,
      sticky_until: 1.week.from_now,
      stripped: true,
      dethreaded: false,
      unread_for: oauth_user,
      starred_by: oauth_user
    )
    first_posting = post.postings.first
    second_posting = create(:posting, post: post)
    post.update!(followup_newsgroup_id: second_posting.newsgroup_id)

    get post_path(post)

    expect(response).to be_successful
    expect(response_json.keys).to eq [:post]
    expect(response_json[:post]).to eq({
      id: post.id,
      created_at: post.date.iso8601,
      subject: post.subject,
      message_id: post.message_id,
      headers: post.headers,
      body: post.body,
      author: {
        name: post.author_name,
        email: post.author_email,
        raw: post.author_raw
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

  it 'retrieves info about the thread containing a single post' do
    root = create(:post)
    descendants = [
      first_reply = create(:post, parent: root, date: 7.hours.ago),
      second_reply = create(:post, parent: root, date: 3.hours.ago),
      second_nested_reply = create(:post, parent: first_reply, date: 1.hour.ago),
      first_nested_reply = create(:post, parent: first_reply, date: 4.hours.ago),
      third_nested_reply = create(:post, parent: second_reply, date: 2.hours.ago)
    ]

    get post_path(first_reply, as_thread: true)

    expect(response).to be_successful
    expect(response_json.keys).to eq [:post, :descendants]
    expect(response_json[:post][:id]).to eq root.id
    expect(response_json[:post][:descendant_ids]).to eq descendants.sort_by(&:date).map(&:id)
    expect(response_json[:post][:child_ids]).to eq [first_reply.id, second_reply.id]
    expect(response_json[:descendants][0][:child_ids]).to eq [first_nested_reply.id, second_nested_reply.id]
    expect(response_json[:descendants][2][:child_ids]).to eq [third_nested_reply.id]
    [1, 3, 4].each{ |num| expect(response_json[:descendants][num][:child_ids]).to eq [] }
  end
end
