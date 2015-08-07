FactoryGirl.define do
  factory :newsgroup do
    id { Faker::Lorem.words.join('.') }
    status { %w(y n).sample }
  end

  factory :oauth_access_token, class: Doorkeeper::AccessToken do
    association :application, factory: :oauth_application
    resource_owner_id { create(:user).id }
  end

  factory :oauth_application, class: Doorkeeper::Application do
    association :owner, factory: :user
    name { Faker::App.name }
    redirect_uri { "https://#{Faker::Internet.domain_name}/redirect" }
  end

  factory :post do
    id { "#{Faker::Lorem.characters(12)}@#{Faker::Internet.domain_name}" }
    subject { Faker::Lorem.sentence }
    author_name { Faker::Name.name }
    author_email { Faker::Internet.email }
    author_raw { "\"#{author_name}\" <#{author_email}>" }
    headers File.read(Rails.root.join('spec', 'support', 'dummy_headers.txt'))
    body { Faker::Lorem.paragraphs(2).join("\n\n") }

    transient do
      newsgroups []
      unread_for nil
      starred_by nil
    end

    after(:build) do |post, evaluator|
      newsgroups = evaluator.newsgroups.presence || post.parent.try(:newsgroups) || [create(:newsgroup)]
      newsgroups.each do |newsgroup|
        post.postings << build(:posting, post: post, newsgroup: newsgroup)
      end

      if evaluator.unread_for.present?
        post.unreads << build(:unread, post: post, user: evaluator.unread_for)
      end

      if evaluator.starred_by.present?
        post.stars << build(:star, post: post, user: evaluator.starred_by)
      end
    end
  end

  factory :posting do
    newsgroup
    post
    sequence(:number)
  end

  factory :star do
    post
    user
  end

  factory :unread do
    post
    user
    personal_level 0
    user_created false
  end

  factory :user do
    username { Faker::Internet.user_name + rand(1000).to_s }
    display_name { Faker::Name.name }

    after(:build) do |user|
      # FIXME: Default "test" subscriptions should probably have email_level 0
      user.subscriptions << Subscription.new(NEW_USER_SUBSCRIPTIONS.first.merge(user: user))
    end
  end
end
