# frozen_string_literal: true

module IsbfCalendar
  class BaseController < ::ApplicationController
    requires_plugin IsbfCalendar::PLUGIN_NAME
  end
end
