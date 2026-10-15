# frozen_string_literal: true

IsbfResume::Engine.routes.draw do
  resources :shares, only: %i[index show create] do
    post :review, on: :member
    get :download, path: "pdf", on: :member, format: false
    get "previews/:page", action: :preview, on: :member, format: false
  end
  get "/page" => "pages#index"
  post "/exports" => "exports#create"
  get "/exports/:export_id/previews/:page" => "exports#preview", :format => false
  get "/exports/:export_id/:file_type" => "exports#download",
      :constraints => {
        file_type: /docx|pdf/,
      }
end
