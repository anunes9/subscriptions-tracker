Rails.application.routes.draw do
  post "billing/checkout", to: "billing#checkout", as: :billing_checkout
  post "billing/webhook", to: "billing#webhook", as: :billing_webhook

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  root "inertia_example#index"
  get "inertia-example", to: "inertia_example#index"

  get "login/passwordless", to: "passwordless_login_requests#new", as: :new_passwordless_login_request
  post "login/passwordless", to: "passwordless_login_requests#create", as: :passwordless_login_requests
  get "login/passwordless/verify", to: "passwordless_login_requests#show", as: :verify_passwordless_login_request
  post "login/passwordless/verify", to: "passwordless_login_requests#verify", as: :verify_passwordless_login_request_code
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
