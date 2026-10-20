require "/var/www/discourse/config/boot"
require "json"
require "yaml"
require "erb"
require "sassc"
require "active_support/core_ext/object/blank"

root = "/workspace"
output = "/review"
source = File.read("#{root}/themes/isbf-campus-feed/stylesheets/elastic-not-found.scss")
File.write("#{output}/elastic-not-found.css", SassC::Engine.new(source, style: :expanded).render)

class SiteSetting
  def self.title
    "ISBF - One"
  end
end

module SvgSprite
  def self.raw_svg(name)
    '<svg class="fa d-icon" viewBox="0 0 16 16" aria-hidden="true"><path d="M5 2L14 8 5 14Z" fill="currentColor"/></svg>'
  end
end

class Preview
  def initialize(locale)
    @translations = YAML.safe_load_file("/workspace/config/locales/server.#{locale}.yml", aliases: true).fetch(locale)
  end

  def t(key)
    @translations.dig(*key.split(".")) || raise("Missing translation: #{key}")
  end

  def application_logo_url
    ""
  end

  def path(value)
    value
  end

  def script_asset_path(_value)
    "/elastic-not-found.js"
  end

  def render
    ERB.new(File.read("/workspace/app/views/exceptions/_elastic_not_found.html.erb")).result(binding)
  end
end

shared = File.read("#{root}/themes/isbf-campus-feed/common/common.scss")[/:root \{.*?\n\}/m]
raise "Shared variables missing" unless shared
color = File.read("#{output}/active-color-schemes.css")
css = File.read("#{output}/elastic-not-found.css")
base = "html, body { margin: 0; } *, *::before, *::after { box-sizing: border-box; } a { text-decoration: none; } button { font: inherit; } .btn { display: inline-flex; justify-content: center; align-items: center; border: 0; cursor: pointer; } .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); }"
%w[zh_CN en].each do |locale|
  File.write("#{output}/#{locale}.html", "<!doctype html><html lang='#{locale}'><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>404 · ISBF - One</title><style>#{color}\n#{shared}\n#{base}\n#{css}</style><body class='no-ember elastic-not-found-page'>#{Preview.new(locale).render}<script type='module' src='/elastic-not-found.js'></script></body></html>")
end
File.write("#{output}/elastic-not-found.js", File.read("#{root}/frontend/discourse/scripts/js/elastic-not-found.js"))
puts "Compiled actual SCSS and rendered the actual ERB with both locales"
