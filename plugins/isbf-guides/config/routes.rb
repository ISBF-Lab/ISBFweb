# frozen_string_literal: true

IsbfGuides::Engine.routes.draw do
  namespace :admin do
    resources :guides, only: %i[index show create update], constraints: { id: /\d+/ } do
      collection do
        post :import, action: :import_document
        get :template
      end
      member do
        post :import, action: :import_document
        get :source
        post :publish
        post :unpublish
        post :images, action: :upload_image
      end
    end
  end
end
