# frozen_string_literal: true

module ::IsbfJoin
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace IsbfJoin
  end
end
