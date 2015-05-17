Rails.application.routes.draw do
  root to: 'frontend#show'
  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

  scope format: false, constraints: { id: /[^\/\?]+/ } do
    resources :newsgroups, only: :index
    resources :posts, only: [:index, :show, :create, :destroy] do
      resource :star, only: [:create, :destroy]
      resource :sticky, only: :update
    end
    resource :unreads, only: [:create, :destroy]
    resource :user, only: :show
  end
end
