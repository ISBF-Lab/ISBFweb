# frozen_string_literal: true

module ::IsbfJoin
  class PublicController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    skip_before_action :redirect_to_login_if_required,
                       :redirect_to_profile_if_required,
                       :preload_json,
                       :initialize_application_layout_preloader,
                       :check_xhr
  end
end
