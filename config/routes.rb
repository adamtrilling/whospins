Spinmap::Application.routes.draw do
 get "pages/index"
  root :to => 'pages#index'

  resources :users, :only => [:index, :show, :edit, :update ]
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'

  get '/tiles/:z/:x/:y.png' => 'tiles#show'
end
