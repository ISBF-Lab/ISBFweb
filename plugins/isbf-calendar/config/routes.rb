# frozen_string_literal: true

IsbfCalendar::Engine.routes.draw do
  get "/api/entries" => "entries#index"
  get "/api/entry-updates" => "entries#updates"
  get "/api/entries/:id" => "entries#show"
  post "/api/entries" => "entries#create"
  post "/api/official-items/:id/add" => "official_items#add"
  post "/api/entries/:id/accept-update" => "entries#accept_update"
  post "/api/entries/:id/dismiss-update" => "entries#dismiss_update"
  patch "/api/entries/:id" => "entries#update"
  delete "/api/entries/:id" => "entries#destroy"

  get "/calendar" => "pages#respond"
  get "/workbench" => "pages#respond"
end

Discourse::Application.routes.draw { mount ::IsbfCalendar::Engine, at: "/isbf" }
