Rails.application.routes.draw do
  # Root Dashboard
  root "dashboard#index"

  # Rails 8 Authentication & Registration
  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token
  resource :registration, only: %i[new create]

  # Projects & Tasks (with Turbo Streams)
  resources :projects, only: %i[create destroy]
  resources :tasks, only: %i[create destroy] do
    member do
      patch :toggle
    end
  end

  # Solid Queue & Cache Demo
  get "jobs/test" => "jobs#show", as: :jobs_test
  post "jobs/trigger" => "jobs#trigger", as: :trigger_jobs

  # Rails 8 Modern Stack Guide
  get "guide" => "guide#index", as: :guide
  get "guide/solid-trio" => "guide#solid_trio", as: :solid_trio_guide

  # Health Check & PWA
  get "up" => "rails/health#show", as: :rails_health_check
end
