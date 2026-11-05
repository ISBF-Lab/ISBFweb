# frozen_string_literal: true

IsbfMbti::Engine.routes.draw do
  resources :questionnaires, only: %i[index show]
  resources :results, only: %i[index show create destroy]
end
