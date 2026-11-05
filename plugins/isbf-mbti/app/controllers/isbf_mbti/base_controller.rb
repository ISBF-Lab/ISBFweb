# frozen_string_literal: true

module IsbfMbti
  class BaseController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    before_action :ensure_mbti_enabled

    private

    def ensure_mbti_enabled
      raise Discourse::NotFound unless SiteSetting.isbf_mbti_enabled
    end
  end
end
