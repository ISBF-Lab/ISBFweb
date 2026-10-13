# frozen_string_literal: true

module IsbfResume
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace IsbfResume
  end
end
