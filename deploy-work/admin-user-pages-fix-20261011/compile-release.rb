# frozen_string_literal: true

require "fileutils"
require "json"

public_root = Rails.public_path.join("assets")
manifest_path = public_root.join(".manifest.json")
manifest = JSON.parse(File.read(manifest_path))
previous_entries = manifest.dup
unless manifest.values.all? { |entry| entry["integrity"].nil? }
  raise "Unexpected asset integrity configuration"
end

delta = Pathname.new("/tmp/user-pages-public-delta")
FileUtils.mkdir_p(delta)
AssetProcessor.timeout = 120_000
published = []
%w[discourse-academy-roles].each do |name|
  plugin = Discourse.plugins.find { |candidate| candidate.directory_name == name }
  raise "Required plugin unavailable" unless plugin

  Plugin::JsManager.new.compile_js_bundle(plugin)
  generated = Rails.root.join("app/assets/generated", name)
  plugin_assets = []
  Dir
    .glob("{js,map}/plugins/*", base: generated)
    .each do |relative|
      source = generated.join(relative)
      next unless source.file?
      raise "Asset is not fingerprinted" if relative.exclude?(".digested.js")

      destination = public_root.join(relative)
      FileUtils.mkdir_p(destination.dirname)
      FileUtils.cp(source, destination)
      manifest[relative] = { "digested_path" => relative, "integrity" => nil }
      delta_file = delta.join(relative)
      FileUtils.mkdir_p(delta_file.dirname)
      FileUtils.cp(destination, delta_file)
      if relative.end_with?(".js")
        system(
          "brotli",
          "-f",
          "--quality=6",
          destination.to_s,
          "--output=#{destination}.br",
          exception: true,
        )
        FileUtils.cp("#{destination}.br", "#{delta_file}.br")
      end
      plugin_assets << relative
    end
  raise "Plugin main bundle missing" unless plugin_assets.any? { |path| path.include?("_main.") }
  published.concat(plugin_assets)
end
unless previous_entries.all? { |key, value| manifest[key] == value }
  raise "Unrelated manifest entry changed"
end

File.write(manifest_path, JSON.generate(manifest))
FileUtils.cp(manifest_path, delta.join(".manifest.json"))
Stylesheet::Manager.recalculate_fs_asset_cachebuster!
puts JSON.generate(
       compiled_plugins: 1,
       published_assets: published.length,
       existing_manifest_preserved: true,
     )
