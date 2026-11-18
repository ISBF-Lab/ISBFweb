# frozen_string_literal: true

require "json"
require "digest"

unless Rails.env.development? && ENV["ISBF_DEV_ENVIRONMENT"] == "1" &&
         ActiveRecord::Base.connection_db_config.database == "discourse_development"
  abort "Requires the isolated development database"
end

input = JSON.parse(STDIN.read)
theme = Theme.find(4)
paths = %w[
  common/common.scss
  stylesheets/forum-assistant.scss
  javascripts/discourse/api-initializers/isbf-forum-assistant.gjs
]
fields =
  paths.to_h do |path|
    opts = ThemeField.opts_from_file_path(path)
    [
      path,
      theme.theme_fields.find_by(
        target_id: Theme.targets[opts.fetch(:target).to_sym],
        name: opts.fetch(:name),
      ),
    ]
  end
snapshot = {
  fields:
    fields.to_h do |path, field|
      [
        path,
        field &&
          { id: field.id, value: field.value, sha256: Digest::SHA256.hexdigest(field.value) },
      ]
    end,
  hashes: theme.theme_fields.to_h { |field| [field.id, Digest::SHA256.hexdigest(field.value)] },
}
if input.fetch("mode") == "capture"
  puts snapshot.to_json
  exit
end
abort "Unknown mode" unless input["mode"] == "apply"
theme.transaction do
  paths.each do |path|
    field = fields.fetch(path)
    expected = input.fetch("expected_hashes")[path]
    if field && Digest::SHA256.hexdigest(field.value) != expected
      abort "Concurrent theme change for #{path}"
    end
    value = File.read("/workspace/external/active-theme/#{path}")
    if path == "common/common.scss"
      value = field.value
      if value.exclude?('@use "forum-assistant";')
        anchor = '@use "alumni-map-distribution";'
        abort "Missing import anchor" if value.exclude?(anchor)
        value = value.sub(anchor, anchor + "\n" + '@use "forum-assistant";')
      end
    end
    theme.set_field(**ThemeField.opts_from_file_path(path).merge(value: value))
  end
  theme.save!
end
after = theme.reload.theme_fields.to_h { |field| [field.id, Digest::SHA256.hexdigest(field.value)] }
changed = after.select { |id, hash| snapshot[:hashes][id] != hash }.keys
errors = theme.theme_fields.where.not(error: [nil, ""]).pluck(:id, :error)
abort "Theme errors: #{errors.to_json}" if errors.any?
puts(
  {
    changed: changed,
    preserved_fields: after.size - changed.size,
    field_count: after.size,
    errors: errors,
  }.to_json,
)
