# frozen_string_literal: true

# name: isbf-join
# about: Public recruitment registration with administrator-only application records.
# version: 0.1.1
# authors: ISBF Lab
# required_version: 3.4.0

module ::IsbfJoin
  PLUGIN_NAME = "isbf-join"
  MAX_BODY_BYTES = 4096
  RATE_LIMIT_COUNT = 20
  RATE_LIMIT_WINDOW = 10.minutes
  PAGE_SIZE = 50
end

add_admin_route "isbf_join.admin.title", "isbf-join", use_new_show_route: true
Rails.application.config.filter_parameters += %i[name studentId student_id phone]

require_relative "lib/isbf_join/application_fields"
require_relative "lib/isbf_join/engine"
require_relative "lib/isbf_join/assets"

after_initialize do
  Discourse::Application.routes.prepend do
    get "/join" => "isbf_join/pages#index"
    get "/join/*asset_path" => "isbf_join/pages#asset", :format => false
    post "/api/applications" => "isbf_join/applications#create", :defaults => { format: :json }
    get "/admin/plugins/isbf-join/applications" => "admin/plugins#index",
        :constraints => AdminConstraint.new
    mount ::IsbfJoin::Engine, at: "/isbf/join"
  end
end
