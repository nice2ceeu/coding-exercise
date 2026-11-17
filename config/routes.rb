Rails.application.routes.draw do
  resources :projects do
    # Tasks are created in the context of a project; updating one only needs
    # the task's own id, so the member routes are shallow.
    resources :tasks, only: %i[create update], shallow: true
  end

  # Health check for load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  root "projects#index"
end
