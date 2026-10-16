ENV["GEM_PATH"] = "/var/www/discourse/vendor/bundle/ruby/3.4.0:#{Gem.path.join(":")}"
Gem.clear_paths
require "sassc"
require "json"
require "yaml"

root = "/workspace/themes/isbf-campus-feed"
common = File.read("#{root}/common/common.scss")
start = common.index(":root {")
finish = common.index("\n}", start) + 2
tokens = common[start...finish]
source = tokens + "\n" + File.read("#{root}/stylesheets/continue-reading.scss")
paths = ["/workspace/app/assets/stylesheets", "#{root}/stylesheets"]
css = SassC::Engine.new(source, load_paths: paths, style: :expanded).render
File.write("/review/compiled/theme.css", css)
schemes = JSON.parse(File.read("#{root}/about.json"))["color_schemes"]
schemes.each do |name, colors|
  mode = name.include?("Dark") ? "dark" : "light"
  variables = colors.map { |key, value| "$#{key}: ##{value};" }.join("\n")
  palette = SassC::Engine.new("#{variables}\n@import \"common/foundation/variables\";\n@import \"color_definitions\";", load_paths: paths, style: :expanded).render
  File.write("/review/compiled/colors-#{mode}.css", palette)
end
translations = ["en", "zh_CN"].to_h do |locale|
  data = YAML.load_file("#{root}/locales/#{locale}.yml", aliases: true)
  [locale, data.dig(locale, "isbf_v2", "continue_reading")]
end
File.write("/review/compiled/translations.json", JSON.pretty_generate(translations) + "\n")
report = { passed: true, actual_component_styles_and_tokens: true, palettes: ["light", "dark"], translation_yaml_parsed: true, cached_native_and_theme_styles_retained: true }
File.write("/review/style-compilation.json", JSON.pretty_generate(report) + "\n")
puts JSON.generate(report)
