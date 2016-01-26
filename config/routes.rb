Rails.application.routes.draw do
  get 'password_resets/new'

  get 'password_resets/edit'

  get 'sessions/new'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root 'static_pages#home'

  get 'help' => 'static_pages#help'

  get 'about' => 'static_pages#about'

  get 'signup' => 'users#new'

  get 'login' => 'sessions#new'

  post 'login' => 'sessions#create'

  delete 'logout' => 'sessions#destroy'

  get 'queries' => 'queries#list'

  get 'new_query' => 'queries#new'

  match 'confirm' => 'queries#confirm', via: [:get, :post]

  resources :users, only: [:new, :create, :destroy, :update, :edit]

  resources :account_activations, only: [:edit]

  resources :password_resets, only: [:new, :create, :edit, :update]

  resources :queries, only: [:show, :create, :destroy, :confirm]

  resources :queries, :new => { :confirm => :post }

  # resources :queries, :new => { :confirm => :post }

end
