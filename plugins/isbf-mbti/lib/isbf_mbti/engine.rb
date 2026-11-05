# frozen_string_literal: true

module IsbfMbti
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace IsbfMbti
  end
end
