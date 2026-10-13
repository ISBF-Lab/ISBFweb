# frozen_string_literal: true

module IsbfResume
  class PagesController < BaseController
    requires_login

    def index
      raise Discourse::InvalidAccess unless guardian.can_generate_isbf_resume?
      render body: nil
    end
  end
end
