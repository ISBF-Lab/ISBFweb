# frozen_string_literal: true
ENV["GEM_PATH"] = "/var/www/discourse/vendor/bundle/ruby/3.4.0:#{Gem.path.join(":")}"
Gem.clear_paths
require "sassc"
require "json"
require "digest"
require "fileutils"

root = "/workspace"
review = "/review"
schemes = JSON.parse(File.read("#{root}/themes/isbf-campus-feed/about.json")).fetch("color_schemes")
results = []
FileUtils.mkdir_p("#{review}/compiled")
schemes.each do |name, colors|
  mode = name.include?("Dark") ? "dark" : "light"
  variables = colors.map { |key, value| "$#{key}: ##{value.delete_prefix("#")};" }.join("\n")
  prefix = [
    '@use "lib/viewport";',
    variables,
    '@import "common/foundation/variables";',
    '@import "common/foundation/mixins";',
  ].join("\n")
  %w[before candidate].each do |version|
    paths = [
      "#{review}/source/live-#{version}/stylesheets",
      "#{review}/source/live-styles",
      "#{root}/app/assets/stylesheets",
    ]
    compile = ->(source) do
      SassC::Engine.new(source, load_paths: paths, style: :expanded, quiet: true).render
    end
    if version == "before"
      File.write(
        "#{review}/compiled/colors-#{mode}.css",
        compile.call(prefix + "\n@import \"color_definitions\";"),
      )
    end
    common = File.read("#{review}/source/live-#{version}/common/common.scss")
    css = compile.call(prefix + "\n" + common.sub('@use "lib/viewport";', ""))
    File.write("#{review}/compiled/#{version}-#{mode}.css", css)
    results << {
      version: version,
      palette: mode,
      bytes: css.bytesize,
      sha256: Digest::SHA256.hexdigest(css),
    }
  end
end
report = {
  passed: true,
  source: "Complete current database theme and native post CSS",
  extra_stylesheets: Dir["#{review}/source/live-styles/*.scss"].size,
  results: results,
}
File.write("#{review}/style-compilation.json", JSON.pretty_generate(report) + "\n")
puts JSON.generate(report)
