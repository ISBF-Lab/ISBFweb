# frozen_string_literal: true

IsbfJoin::Engine.routes.draw do
  namespace :admin do
    get "/applications" => "applications#index", :defaults => { format: :json }
  end
end
