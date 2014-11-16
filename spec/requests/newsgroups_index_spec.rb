require 'rails_helper'

RSpec.describe 'Newsgroups index' do
  it 'retrieves info about all newsgroups' do
    first_group = create(:newsgroup, name: 'test.one', status: 'y', updated_at: 2.minutes.ago)
    second_group = create(:newsgroup, name: 'test.two', status: 'n', updated_at: 1.minute.ago)
    third_group = create(:newsgroup, name: 'test.three', status: 'y', updated_at: 3.minutes.ago)
    first_post = create(:post, created_at: 5.years.ago, newsgroups: [first_group])
    second_post = create(:post, created_at: 2.months.ago, newsgroups: [first_group, third_group])
    third_post = create(:post, created_at: 9.days.ago, newsgroups: [first_group])
    create(:unread_post_entry, user: oauth_user, post: second_post, personal_level: 1)
    create(:unread_post_entry, user: oauth_user, post: third_post, personal_level: 2)
    allow(Flag).to receive(:last_full_news_sync_at).and_return(2.minutes.ago)

    get newsgroups_path

    expect(response).to be_successful
    expect(response_json.keys).to match_array [:meta, :newsgroups]
    expect(response_json[:meta]).to eq({ last_sync_at: Flag.last_full_news_sync_at.iso8601 })
    expect(response_json[:newsgroups].size).to be 3
    expect(response_json[:newsgroups][0]).to eq({
      id: first_group.id,
      name: 'test.one',
      posting_allowed: true,
      updated_at: first_group.updated_at.iso8601,
      unread_count: 2,
      unread_personal_level: 2,
      newest_post_at: third_post.created_at.iso8601,
      oldest_post_at: first_post.created_at.iso8601
    })
    expect(response_json[:newsgroups][1]).to eq({
      id: second_group.id,
      name: 'test.two',
      posting_allowed: false,
      updated_at: second_group.updated_at.iso8601,
      unread_count: 0,
      unread_personal_level: nil,
      newest_post_at: nil,
      oldest_post_at: nil
    })
    expect(response_json[:newsgroups][2]).to eq({
      id: third_group.id,
      name: 'test.three',
      posting_allowed: true,
      updated_at: third_group.updated_at.iso8601,
      unread_count: 1,
      unread_personal_level: 1,
      newest_post_at: second_post.created_at.iso8601,
      oldest_post_at: second_post.created_at.iso8601
    })
  end
end
