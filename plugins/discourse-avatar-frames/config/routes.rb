# frozen_string_literal: true

DiscourseAvatarFrames::Engine.routes.draw do
  scope "/admin", defaults: { format: :json } do
    resources :frames, only: %i[index show create update] do
      resources :grants, only: %i[index create], param: :user_id
      delete "grants/:user_id" => "grants#destroy"
      resources :imports, only: %i[index create]
    end
    resources :uploads, only: [:create]
    resources :imports, only: [:show]
  end
end

Discourse::Application.routes.draw do
  mount DiscourseAvatarFrames::Engine, at: "/avatar-frames"
  get "/admin/plugins/discourse-avatar-frames/frames(/*path)" => "admin/plugins#show",
      :defaults => {
        plugin_id: "discourse-avatar-frames",
      },
      :constraints => AdminConstraint.new
  get "/plugins/discourse-avatar-frames/images/:key-static.png" =>
        "discourse_avatar_frames/images#show",
      :defaults => {
        static: true,
      },
      :constraints => {
        key: /[0-9a-f-]{36}/,
      }
  get "/plugins/discourse-avatar-frames/images/:key.png" => "discourse_avatar_frames/images#show",
      :constraints => {
        key: /[0-9a-f-]{36}/,
      }
end
