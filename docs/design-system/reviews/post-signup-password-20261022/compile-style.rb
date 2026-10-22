# frozen_string_literal: true
ENV["GEM_PATH"] = "/var/www/discourse/vendor/bundle/ruby/3.4.0:#{Gem.path.join(":")}"
Gem.clear_paths
require "sassc"
require "json"
require "yaml"
require "digest"

root = "/workspace/themes/isbf-campus-feed"
common = File.read("#{root}/common/common.scss")
paths = ["/workspace/app/assets/stylesheets", "#{root}/stylesheets"]
schemes = JSON.parse(File.read("#{root}/about.json"))["color_schemes"]
colors = schemes.find { |name, _| name.include?("Light") }.last
variables = colors.map { |key, value| "$#{key}: ##{value.delete_prefix("#")};" }.join("\n")
source = [
  '@use "lib/viewport";',
  variables,
  '@import "common/foundation/variables";',
  '@import "common/foundation/mixins";',
  common.sub('@use "lib/viewport";', ""),
].join("\n")
compile = ->(scss) do
  SassC::Engine.new(scss, load_paths: paths, style: :expanded, quiet: true).render
end
File.write("/review/compiled/theme.css", compile.call(source))
schemes.each do |name, palette|
  mode = name.include?("Dark") ? "dark" : "light"
  values = palette.map { |key, value| "$#{key}: ##{value.delete_prefix("#")};" }.join("\n")
  File.write(
    "/review/compiled/colors-#{mode}.css",
    compile.call(
      "#{values}\n@import \"common/foundation/variables\";\n@import \"color_definitions\";",
    ),
  )
end
translations =
  %w[en zh_CN].to_h do |locale|
    data =
      YAML.load_file(
        "/workspace/plugins/discourse-academy-roles/config/locales/client.#{locale}.yml",
        aliases: true,
      )
    [locale, data.dig(locale, "js", "academy_roles", "password_setup")]
  end
File.write("/review/compiled/translations.json", JSON.pretty_generate(translations) + "\n")
report = {
  passed: true,
  complete_workspace_common_scss: true,
  palettes: %w[light dark],
  locales: translations.keys,
  common_scss_sha256: Digest::SHA256.hexdigest(common),
}
File.write("/review/style-compilation.json", JSON.pretty_generate(report) + "\n")
puts JSON.generate(report)
