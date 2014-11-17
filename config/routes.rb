Rails.application.routes.draw do
  root to: 'client#show'
  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

  resources :newsgroups, only: :index
  resources :posts, only: [:index, :show, :create, :destroy] do
    resource :star, only: [:create, :destroy]
    resource :sticky, only: :update
  end
  resource :unreads, only: [:create, :destroy]
  resource :user, only: :show
end
