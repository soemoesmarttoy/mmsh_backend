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

  delete "pre_produces/delete(/:temp_id)", to: "pre_sells#delete"
  get "pre_produces/withdrawn(/:temp_id/:new_temp_id)", to: "pre_sells#withdrawn"
  get "products/get-all-products", to: "products#get_all_products"
  get "users/get-emails", to: "users#get_emails"
  get "users/get-usernames", to: "users#get_usernames"
  post "users", to: "users#create"
  get "users", to: "users#index"
  put "users", to: "users#update"
  post "users/check-password", to: "users#check_password"
  post "pre-produces-rent-dried-collect", to: "pre_sells#rent_dried_collect"
  post "pre-produces-rent-buy", to: "pre_sells#rent_buy"
  post "create-income-rent-collect", to: "pre_sells#rent_collect"
  put "update-pre-produce", to: "pre_sells#update_pre_produce"
  post "get-product-balance-by-many", to: "pre_sells#get_product_balance_by_many"
  get "get-pre-produce(/:temp_id)", to: "pre_sells#get_pre_produce"
  post "create-pre-produce", to: "pre_sells#pre_produce"
  post "settle_pre_sells", to: "pre_sells#settle"
  post "pre_sells", to: "pre_sells#create"
  get "pre_sells", to: "pre_sells#get_pre_sells"
  get "get-profits", to: "profits#get_profits"
  get "expense_categories", to: "expense_categories#index"
  post "expense_categories", to: "expense_categories#create"
  post "create_expense", to: "expense_categories#create_expense"
  get "income_categories", to: "income_categories#index"
  post "income_categories", to: "income_categories#create"
  post "create_income", to: "income_categories#create_income"
  get "orders", to: "orders#index"
  post "orders", to: "orders#create"
  put "orders", to: "orders#update"
  post "create-settle-to-pay-order", to: "orders#settle_to_pay"
  post "create-settle-to-receive-order", to: "orders#settle_to_receive"
  post "create-production-order", to: "orders#create_production_order"
  get "orders/get-product-balance/:product_id", to: "orders#get_product_balance"
  get "orders/get-cash-balance", to: "orders#get_cash_balance"
  get "orders/get-to-pay-orders", to: "orders#get_to_pay_orders"
  get "orders/get-to-receive-orders", to: "orders#get_to_receive_orders"
  get "orders/:order_id", to: "orders#get_order_by_id"
  get "reports/buy_report", to: "reports#buy_report"
  get "reports/sell_report", to: "reports#sell_report"
  get "reports/cash_report", to: "reports#cash_report"
  get "reports/production_report", to: "reports#production_report"
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
