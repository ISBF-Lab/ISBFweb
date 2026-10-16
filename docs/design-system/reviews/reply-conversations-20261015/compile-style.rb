ENV["GEM_PATH"] = "/var/www/discourse/vendor/bundle/ruby/3.4.0:#{Gem.path.join(":")}"
Gem.clear_paths
require "sassc"
require "json"
require "fileutils"
require "yaml"

root = "/workspace"
common = File.read("#{root}/themes/isbf-campus-feed/common/common.scss")
extract = lambda do |marker|
  start = common.index(marker) or raise "Missing source block: #{marker}"
  opening = common.index("{", start)
  depth = 1
  ending = opening + 1
  while depth.positive? && ending < common.length
    depth += 1 if common[ending] == "{"
    depth -= 1 if common[ending] == "}"
    ending += 1
  end
  common[start...ending]
end
paths = ["#{root}/app/assets/stylesheets", "#{root}/themes/isbf-campus-feed/stylesheets"]
schemes = JSON.parse(File.read("#{root}/themes/isbf-campus-feed/about.json"))["color_schemes"]
light = schemes.find { |name, _colors| name.include?("Light") }.last
palette = light.map { |key, value| "$#{key}: ##{value.delete_prefix("#")};" }.join("\n")
source = [
  '@use "lib/viewport";',
  palette,
  '@import "common/foundation/variables";',
  '@import "common/foundation/mixins";',
  extract.call(":root {"),
  extract.call("@mixin isbf-card-content"),
  extract.call("@mixin isbf-card-actions"),
  '@import "common/nested-view";',
  '@import "common/topic-timeline";',
  "body:has(.isbf-v2-shell--topic-feed-style) { #{extract.call("  .isbf-post-card-header {")} #{extract.call("  .topic-navigation {\n")} }",
  '@import "topic-reading";',
  '@import "reply-conversations";'
].join("\n")
compile = lambda do |scss|
  SassC::Engine.new(scss, load_paths: paths, style: :expanded, quiet: true).render
end
FileUtils.mkdir_p("/review/compiled")
css = compile.call(source)
File.write("/review/compiled/conversations.css", css)
schemes.each do |name, colors|
  mode = name.include?("Dark") ? "dark" : "light"
  variables = colors.map { |key, value| "$#{key}: ##{value.delete_prefix("#")};" }.join("\n")
  palette = compile.call("#{variables}\n@import \"common/foundation/variables\";\n@import \"color_definitions\";")
  File.write("/review/compiled/colors-#{mode}.css", palette)
end
report = {
  scss_compiled: true,
  bytes: css.bytesize,
  scope: "Actual native nested/timeline styles, theme tokens, approved header/action mixins, and conversation stylesheet"
}
File.write("/review/style-compilation.json", JSON.pretty_generate(report) + "\n")
translations = {
  nested: YAML.load_file("#{root}/config/locales/client.zh_CN.yml", aliases: true).dig("zh_CN", "js", "nested_replies"),
  theme: YAML.load_file("#{root}/themes/isbf-campus-feed/locales/zh_CN.yml", aliases: true).dig("zh_CN", "isbf_v2", "reply_conversations")
}
File.write("/review/compiled/translations.json", JSON.pretty_generate(translations) + "\n")
puts JSON.generate(report)
