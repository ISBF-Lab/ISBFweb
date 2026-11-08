# frozen_string_literal: true

module ::IsbfGuides
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace IsbfGuides
  end
end
