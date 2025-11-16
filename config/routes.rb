SeoAiEngine::Engine.routes.draw do
  namespace :admin do
    resources :opportunities, only: [ :index ] do
      collection do
        post :run_discovery
      end
      member do
        post :dismiss
        post :generate_content
      end
    end

    resources :content_drafts, only: [ :index, :show ] do
      member do
        post :approve
        post :reject
      end
    end

    resources :content_items, only: [ :index, :show ]

    get "performance", to: "performance#index"
  end
end
