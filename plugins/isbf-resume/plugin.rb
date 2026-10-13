# frozen_string_literal: true

# name: isbf-resume
# about: Private mechanical resume generation for the ISBF workbench
# version: 0.1.0
# authors: ISBF Lab
# required_version: 3.4.0

enabled_site_setting :isbf_resume_enabled

module ::IsbfResume
  PLUGIN_NAME = "isbf-resume"
  MAX_REQUEST_BYTES = 8.megabytes
  EXPORT_LIFETIME = 24.hours
  GENERATION_TIMEOUT = 90
end

require_relative "lib/isbf_resume/generator"
require_relative "lib/isbf_resume/engine"
register_asset "stylesheets/isbf-resume.scss"
register_svg_icon "file-lines"
register_svg_icon "file-arrow-down"

after_initialize do
  Discourse::Application.routes.prepend do
    get "/isbf/workbench/resume" => "isbf_resume/pages#index"
    mount ::IsbfResume::Engine, at: "/isbf-resume"
  end

  require_relative "app/models/isbf_resume/export"
  require_relative "app/services/isbf_resume/export/generate"
  require_relative "app/serializers/isbf_resume/export_serializer"
  require_relative "lib/isbf_resume/guardian_extension"

  reloadable_patch { Guardian.prepend ::IsbfResume::GuardianExtension }

  Rails.application.config.filter_parameters += %i[resume photo]
end
