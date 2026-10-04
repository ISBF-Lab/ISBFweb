# frozen_string_literal: true

module ::IsbfCalendar
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace IsbfCalendar
  end
end
