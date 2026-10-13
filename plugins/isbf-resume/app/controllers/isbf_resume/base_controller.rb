# frozen_string_literal: true

module IsbfResume
  class BaseController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    prepend_before_action :ensure_resume_access

    private

    def ensure_resume_access
      raise Discourse::NotFound unless SiteSetting.isbf_resume_enabled
      raise Discourse::InvalidAccess unless guardian.can_generate_isbf_resume?
    end
  end
end
