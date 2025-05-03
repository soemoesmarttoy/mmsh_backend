Rails.application.routes.draw do
  get "categories", to: "categories#index"
  post "categories", to: "categories#create"
  put "categories", to: "categories#update"
  delete "categories", to: "categories#delete"
  get "products", to: "products#index"
  post "products", to: "products#create"
  put "products", to: "products#update"
  delete "products", to: "products#delete"

  get "customers", to: "customers#index"
  post "customers", to: "customers#create"
  put "customers", to: "customers#update"

  get "orders", to: "orders#index"
  post "orders", to: "orders#create"
  put "orders", to: "orders#update"
  get "orders/get-cash-balance", to: "orders#get_cash_balance"
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
