Rails.application.routes.draw do
  # Dashboard
  get "dashboards/show"
  root "dashboards#show"

  # Authentication routes (from Week 2)
  resource :session
  resources :users, only: [:new, :create]
  
  # Existing resources
  resources :ingredients
  resources :recipes do
    resource :favorite, only: [:create, :destroy]
  end
  
  # Week 4 resources
  resources :inventory_items
  resources :batches, only: [:index, :show, :new, :create, :destroy]
end
