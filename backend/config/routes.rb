Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"
      delete "auth/logout", to: "auth#logout"

      resources :locations, only: [] do
        collection { get :search }
        resources :forecasts, only: :index
      end
      get "locations/:id/event_days", to: "event_days#show"

      resources :forecasts, only: [] do
        get :hourly, to: "hourly_forecasts#show"
        resources :recommendations, only: :index
        get "recommendations/:recommendation_id/availability",
          to: "activity_availability#show",
          as: :recommendation_availability
        resources :showtimes, only: :index do
          collection { get :booking_link }
        end
      end

      resources :trips, only: %i[index show create update destroy] do
        post :replan, on: :member
        post :replace_item, on: :member
      end
    end
  end
end
