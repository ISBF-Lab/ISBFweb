# frozen_string_literal: true

module IsbfAnonymous
  class PagesController < ::ApplicationController
    requires_plugin IsbfAnonymous::PLUGIN_NAME
    before_action :ensure_logged_in

    def respond
      render body: nil
    end
  end
end
