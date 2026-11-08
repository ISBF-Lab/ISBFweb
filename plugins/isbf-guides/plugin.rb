# frozen_string_literal: true

# name: isbf-guides
# about: Member guides with administrator drafts, publishing and private images.
# version: 0.1.0
# authors: ISBF Lab
# required_version: 3.4.0

enabled_site_setting :isbf_guides_enabled

module ::IsbfGuides
  PLUGIN_NAME = "isbf-guides"
end

require_relative "lib/isbf_guides/engine"
require_relative "lib/isbf_guides/renderer"
require_relative "lib/isbf_guides/document_error"
require_relative "lib/isbf_guides/document_markup"
require_relative "lib/isbf_guides/document_package"
require_relative "lib/isbf_guides/html_renderer"
require_relative "lib/isbf_guides/document_archive"

register_svg_icon "book-open"
add_admin_route "isbf_guides.admin.title", "isbf-guides", use_new_show_route: true

after_initialize do
  add_to_class(:guardian, :can_manage_isbf_guides?) do
    user&.admin? && SiteSetting.isbf_guides_enabled
  end

  Discourse::Application.routes.prepend do
    get "/guides" => "isbf_guides/guides#index"
    get "/guides/:slug/images/:filename" => "isbf_guides/guides#image",
        :format => false,
        :constraints => {
          filename: /[a-zA-Z0-9][a-zA-Z0-9._-]+\.(?:jpg|jpeg|png|webp|gif)/,
        }
    get "/guides/:slug" => "isbf_guides/guides#show"
    get "/admin/plugins/isbf-guides/*path" => "admin/plugins#index",
        :constraints => AdminConstraint.new
    mount ::IsbfGuides::Engine, at: "/isbf/guides"
  end
end
