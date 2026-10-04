# frozen_string_literal: true

IsbfCalendar::Engine.routes.draw do
  get "/api/entries" => "entries#index"
  post "/api/entries" => "entries#create"
  patch "/api/entries/:id" => "entries#update"
  delete "/api/entries/:id" => "entries#destroy"

  get "/calendar" => "pages#respond"
  get "/workbench" => "pages#respond"
end

Discourse::Application.routes.draw { mount ::IsbfCalendar::Engine, at: "/isbf" }
