Webnews::Application.routes.draw do
  root :to => 'pages#home'
  get '/home', :to => 'pages#home'
  get '/about', :to => 'pages#about'
  get '/new_user', :to => 'pages#new_user'
  get '/old_user', :to => 'pages#old_user'
  get '/check_new', :to => 'pages#check_new'
  
  put '/mark_read', :to => 'pages#mark_read', :as => :mark_read
  
  get '/settings', :to => 'users#edit',   :as => :edit_user
  put '/settings', :to => 'users#update', :as => :update_user
  put '/settings/api', :to => 'users#update_api', :as => :update_user_api
  
  get '/compose',  :to => 'posts#new',    :as => :new_post
  post '/compose', :to => 'posts#create', :as => :create_post
  
  get '/search',   :to => 'posts#search', :as => :search
  get '/search_entry', :to => 'posts#search_entry', :as => :search_entry
  
  constraints :newsgroup => /[^\/]*/ do
    get '/:newsgroup/index',          :to => 'posts#index',           :as => :posts
    get '/:newsgroup/:number',        :to => 'posts#show',            :as => :post
    get '/:newsgroup/:number/sticky', :to => 'posts#edit_sticky',     :as => :edit_post_sticky
    put '/:newsgroup/:number/sticky', :to => 'posts#update_sticky',   :as => :update_post_sticky
    put '/:newsgroup/:number/star',   :to => 'posts#update_star',     :as => :update_post_star
    delete '/:newsgroup/:number',     :to => 'posts#destroy',         :as => :destroy_post
    get '/:newsgroup/:number/cancel', :to => 'posts#destroy_confirm', :as => :confirm_destroy_post
  end
end
