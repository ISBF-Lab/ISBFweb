# frozen_string_literal: true

# name: isbf-mbti
# about: Private personality preference tests for the ISBF workbench
# version: 0.1.0
# authors: ISBF Lab
# required_version: 3.4.0

enabled_site_setting :isbf_mbti_enabled
register_svg_icon "brain"

module ::IsbfMbti
  PLUGIN_NAME = "isbf-mbti"
  PAGE_SIZE = 20
end

require_relative "lib/isbf_mbti/engine"
require_relative "lib/isbf_mbti/questionnaire"

after_initialize do
  require_relative "app/models/isbf_mbti/result"
  require_relative "app/serializers/isbf_mbti/result_serializer"
  require_relative "app/controllers/isbf_mbti/base_controller"
  require_relative "app/controllers/isbf_mbti/pages_controller"
  require_relative "app/controllers/isbf_mbti/questionnaires_controller"
  require_relative "app/controllers/isbf_mbti/results_controller"

  Discourse::Application.routes.prepend do
    get "/isbf/mbti" => "isbf_mbti/pages#index", :as => :isbf_mbti_page
    mount ::IsbfMbti::Engine, at: "/isbf/api/mbti", as: :isbf_mbti_api
  end

  add_to_serializer(:site, :isbf_mbti, include_condition: -> { SiteSetting.isbf_mbti_enabled }) do
    { enabled: true, path: "/isbf/mbti" }
  end

  Rails.application.config.filter_parameters += %i[answers attempt_id]

  # rubocop:disable Discourse/Plugins/UsePluginInstanceOn -- Privacy cleanup must run while disabled.
  DiscourseEvent.on(:user_anonymized) do |user:, **|
    IsbfMbti::Result.where(user_id: user.id).delete_all if IsbfMbti::Result.table_exists?
  end
  # rubocop:enable Discourse/Plugins/UsePluginInstanceOn
end
