# frozen_string_literal: true

IsbfResume::Engine.routes.draw do
  get "/page" => "pages#index"
  post "/exports" => "exports#create"
  get "/exports/:export_id/previews/:page" => "exports#preview",
      :format => false
  get "/exports/:export_id/:file_type" => "exports#download",
      :constraints => {
        file_type: /docx|pdf/
      }
end
