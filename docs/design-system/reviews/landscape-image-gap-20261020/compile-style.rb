ENV["GEM_PATH"] = "/var/www/discourse/vendor/bundle/ruby/3.4.0:#{Gem.path.join(":")}"
Gem.clear_paths
require "sassc"
require "json"
require "digest"
require "fileutils"

root = "/workspace"
review = "/review"
theme = "#{root}/themes/isbf-campus-feed"
schemes = JSON.parse(File.read("#{theme}/about.json")).fetch("color_schemes")
core = File.read("#{root}/app/assets/stylesheets/common/base/topic-post.scss")
responsive_images = core.match(/  img:not\(\.thumbnail, \.ytp-thumbnail-image, \.emoji\) \{.*?\n  \}/m)[0]
results = []
FileUtils.mkdir_p("#{review}/compiled")
schemes.each do |name, colors|
  mode = name.include?("Dark") ? "dark" : "light"
  variables = colors.map { |key, value| "$#{key}: ##{value.delete_prefix('#')};" }.join("\n")
  prefix = ['@use "lib/viewport";', variables, '@import "common/foundation/variables";', '@import "common/foundation/mixins";'].join("\n")
  paths = ["#{review}/source/live-styles", "#{root}/app/assets/stylesheets"]
  compile = ->(source) { SassC::Engine.new(source, load_paths: paths, style: :expanded, quiet: true).render }
  colors_css = compile.call(prefix + "\n@import \"color_definitions\";")
  File.write("#{review}/compiled/colors-#{mode}.css", colors_css)
  %w[before candidate].each do |version|
    common = File.read("#{review}/source/live-#{version}/common.scss")
    support = '@import "common/base/lightbox"; @import "common/base/d-image-grid";' + "\n.cooked, .d-editor-preview {\n#{responsive_images}\n}\n"
    css = compile.call(prefix + "\n" + support + common.sub('@use "lib/viewport";', ""))
    File.write("#{review}/compiled/#{version}-#{mode}.css", css)
    results << {version: version, palette: mode, bytes: css.bytesize, sha256: Digest::SHA256.hexdigest(css)}
  end
end
report = {passed: true, source: "complete current database theme with one image-height delta", extra_stylesheets: Dir["#{review}/source/live-styles/*.scss"].size, results: results}
File.write("#{review}/style-compilation.json", JSON.pretty_generate(report) + "\n")
puts JSON.generate(report)
