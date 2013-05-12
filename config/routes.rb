Whospins::Application.routes.draw do
  root :to => 'pages#index'
  get "pages/index"
  get "pages/:page" => 'pages#show', :as => :page

  get '/users/current.:format' => 'users#current'
  resources :users, :only => [:index, :show, :edit, :update ]

  get '/auth/:provider/callback' => 'sessions#create'
  get '/auth/failure' => 'sessions#failure'
  get '/auth/:provider' => 'sessions#new', :as => :login
  get '/logout' => 'sessions#destroy', :as => :logout

  get '/tiles/:z/:x/:y.png' => 'tiles#show'

  get '/locations/children/:id.:format' => 'locations#children'
  get '/locations/overlay/:id.:format' => 'locations#overlay'
end
