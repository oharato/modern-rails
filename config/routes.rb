Rails.application.routes.draw do
  # Root & Catalog (Cached: 60s)
  root "catalog#index"

  # Customer Catalog
  resources :products, param: :slug, only: %i[index show] do
    resources :reviews, only: %i[create]
  end
  get "categories/:slug" => "products#index", as: :category_products

  # Shopping Cart (KV Store)
  resource :cart, only: %i[show] do
    post "items", to: "carts#add_item", as: :add_item
    patch "items/:product_id", to: "carts#update_quantity", as: :update_item
    delete "items/:product_id", to: "carts#remove_item", as: :remove_item
    delete "clear", to: "carts#clear", as: :clear
  end

  # Checkout & Orders
  get "checkout" => "checkouts#show", as: :checkout
  resources :orders, only: %i[create show] do
    member do
      get "complete"
      get "receipt"
    end
    collection do
      get "my"
    end
  end
  get "mypage/orders" => "orders#my", as: :mypage_orders
  get "dashboard" => "dashboard#index", as: :dashboard

  # Architecture Guide
  get "guide" => "guide#index", as: :guide
  get "guide/solid-trio" => "guide#solid_trio", as: :guide_solid_trio

  # Authentication & Registration
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  # Customer Shortcuts
  get "login" => "sessions#new", as: :login
  delete "logout" => "sessions#destroy", as: :logout
  get "signup" => "registrations#new", as: :signup

  # Admin Backoffice
  namespace :admin do
    root to: "dashboard#index"
    resources :products do
      member do
        patch :toggle_publish
        patch :update_stock
      end
    end
    resources :orders, only: %i[index show] do
      member do
        patch :status, to: "orders#update_status", as: :update_status
      end
    end
    get "jobs" => "jobs#index", as: :jobs
    post "jobs/daily_report" => "jobs#trigger_daily_report", as: :trigger_daily_report
    get "cache" => "cache#show", as: :cache_management
    post "cache/purge" => "cache#purge", as: :purge_cache
  end

  # JSON APIs (Section 6 Specification)
  namespace :api do
    # Auth
    post "auth/register", to: "auth#register"
    post "auth/login", to: "auth#login"
    post "auth/logout", to: "auth#logout"
    get  "auth/me", to: "auth#me"

    # Catalog & Cache
    get "products", to: "products#index"
    get "products/:slug", to: "products#show"
    get "categories", to: "categories#index"

    # Reviews
    get  "products/:slug/reviews", to: "reviews#index"
    post "products/:slug/reviews", to: "reviews#create"

    # Cart & KV
    get    "cart", to: "carts#show"
    post   "cart/items", to: "carts#add_item"
    patch  "cart/items/:id", to: "carts#update_quantity"
    delete "cart/items/:id", to: "carts#remove_item"
    get    "user/recently-viewed", to: "recently_viewed#index"

    # Checkout & Orders
    post "orders", to: "orders#create"
    get  "orders/my", to: "orders#my"
    get  "orders/:id/receipt", to: "orders#receipt"

    # Admin
    namespace :admin do
      post  "products", to: "products#create"
      patch "products/:id", to: "products#update"
      get   "orders", to: "orders#index"
      patch "orders/:id/status", to: "orders#update_status"
      post  "jobs/daily-report", to: "jobs#daily_report"
      get   "jobs/logs", to: "jobs#logs"
      post  "cache/purge", to: "cache#purge"
    end
  end

  # Health Check
  get "up" => "rails/health#show", as: :rails_health_check
end
