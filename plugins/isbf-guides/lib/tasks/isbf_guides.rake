# frozen_string_literal: true

namespace :isbf_guides do
  desc "Import the published Android guide once, without replacing subsequent edits"
  task :import_android, %i[directory admin_user_id] => :environment do |_, arguments|
    require_relative "../isbf_guides/legacy_import"
    actor = User.find(arguments.fetch(:admin_user_id))
    guide = IsbfGuides::LegacyImport.call(directory: arguments.fetch(:directory), actor:)
    puts(
      {
        guide_id: guide.id,
        slug: guide.slug,
        images: guide.images.count,
        published: guide.published?,
      }.to_json,
    )
  end
end
