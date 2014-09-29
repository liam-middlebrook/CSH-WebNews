FactoryGirl.define do
  factory :oauth_access_token, class: Doorkeeper::AccessToken do
    association :application, factory: :oauth_application
    resource_owner_id { create(:user).id }
  end

  factory :oauth_application, class: Doorkeeper::Application do
    association :owner, factory: :user
    name { Faker::App.name }
    redirect_uri { Faker::Internet.url }
  end

  factory :user do
    username { Faker::Internet.user_name }
    real_name { Faker::Name.name }
  end
end
