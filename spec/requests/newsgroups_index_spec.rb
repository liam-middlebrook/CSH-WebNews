require 'rails_helper'

RSpec.describe 'Newsgroups index' do
  it 'retrieves info about all newsgroups' do
    first_group = create(:newsgroup, name: 'test.one', status: 'y', updated_at: 2.minutes.ago)
    second_group = create(:newsgroup, name: 'test.two', status: 'n', updated_at: 1.minute.ago)
    third_group = create(:newsgroup, name: 'test.three', status: 'y', updated_at: 3.minutes.ago)
    first_post = create(:post, date: 5.years.ago, newsgroups: [first_group])
    second_post = create(:post, date: 2.months.ago, newsgroups: [first_group, third_group])
    third_post = create(:post, date: 9.days.ago, newsgroups: [first_group])
    create(:unread_post_entry, user: oauth_user, post: second_post, personal_level: 1)
    create(:unread_post_entry, user: oauth_user, post: third_post, personal_level: 2)

    get newsgroups_path

    expect(response).to be_successful
    expect(response_json.keys).to eq [:newsgroups]
    expect(response_json[:newsgroups].size).to be 3
    expect(response_json[:newsgroups][0]).to eq({
      id: first_group.id,
      name: 'test.one',
      status: 'y',
      updated_at: first_group.updated_at.iso8601,
      unread_count: 2,
      unread_personal_level: 2,
      newest_post_at: third_post.date.iso8601,
      oldest_post_at: first_post.date.iso8601
    })
    expect(response_json[:newsgroups][1]).to eq({
      id: second_group.id,
      name: 'test.two',
      status: 'n',
      updated_at: second_group.updated_at.iso8601,
      unread_count: 0,
      unread_personal_level: nil,
      newest_post_at: nil,
      oldest_post_at: nil
    })
    expect(response_json[:newsgroups][2]).to eq({
      id: third_group.id,
      name: 'test.three',
      status: 'y',
      updated_at: third_group.updated_at.iso8601,
      unread_count: 1,
      unread_personal_level: 1,
      newest_post_at: second_post.date.iso8601,
      oldest_post_at: second_post.date.iso8601
    })
  end
end
