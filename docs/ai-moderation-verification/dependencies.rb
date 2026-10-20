# frozen_string_literal: true
ENV["BUNDLE_GEMFILE"] = "/tmp/spec-work/Gemfile"
ENV["BUNDLE_PATH"] = "/test-gems"
ENV["BUNDLE_APP_CONFIG"] = "/tmp/spec-work/.bundle"
ENV["BUNDLE_WITHOUT"] = "development:migrations:generic_import"
ENV["BUNDLE_FROZEN"] = "true"
ENV["GEM_HOME"] = "/test-gems/ruby/3.4.0"
ENV["GEM_PATH"] = "#{ENV["GEM_HOME"]}:/usr/local/lib/ruby/gems/3.4.0"
Gem.clear_paths
require "bundler"
require "json"
missing =
  Bundler.definition.missing_specs.map do |spec|
    { name: spec.name, version: spec.version.to_s, platform: spec.platform.to_s }
  end
puts "MISSING_GEMS=#{missing.to_json}"
