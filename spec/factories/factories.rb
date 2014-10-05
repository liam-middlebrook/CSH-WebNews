FactoryGirl.define do
  factory :newsgroup do
    name { Faker::Lorem.words.join('.') }
    status { %w(y n).sample }
  end

  factory :oauth_access_token, class: Doorkeeper::AccessToken do
    association :application, factory: :oauth_application
    resource_owner_id { create(:user).id }
  end

  factory :oauth_application, class: Doorkeeper::Application do
    association :owner, factory: :user
    name { Faker::App.name }
    redirect_uri { Faker::Internet.url }
  end

  factory :post do
    date { DateTime.now }
    subject { Faker::Lorem.sentence }
    author { "\"#{Faker::Name.name}\" <#{Faker::Internet.email}>" }
    message_id { "#{Faker::Lorem.characters(12)}@#{Faker::Internet.domain_name}" }
    headers File.read(Rails.root.join('spec', 'support', 'dummy_headers.txt'))
    body { Faker::Lorem.paragraphs(2).join("\n\n") }

    ignore { newsgroups [] }

    after(:build) do |post, evaluator|
      newsgroups = evaluator.newsgroups.presence || post.parent.try(:newsgroups) || [create(:newsgroup)]
      newsgroups.each do |newsgroup|
        post.postings << build(:posting, post: post, newsgroup: newsgroup)
      end
    end
  end

  factory :posting do
    newsgroup
    post
    sequence(:number)
  end

  factory :starred_post_entry do
    post
    user
  end

  factory :unread_post_entry do
    post
    user
    personal_level 0
    user_created false
  end

  factory :user do
    username { Faker::Internet.user_name + rand(1000).to_s }
    real_name { Faker::Name.name }
  end
end
