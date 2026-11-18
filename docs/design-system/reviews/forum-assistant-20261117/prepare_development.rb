# frozen_string_literal: true

require "json"
require "yaml"
require "digest"

unless Rails.env.development? && ENV["ISBF_DEV_ENVIRONMENT"] == "1" &&
         ActiveRecord::Base.connection_db_config.database == "discourse_development"
  abort "Requires the isolated development database"
end

input = JSON.parse(STDIN.read)
theme = Theme.find(4)
paths = %w[
  javascripts/discourse/components/isbf-v2-workbench.gjs
  locales/en.yml
  locales/zh_CN.yml
  test/integration/workbench-test.gjs
  stylesheets/workbench.scss
]
fields =
  paths.to_h do |path|
    opts = ThemeField.opts_from_file_path(path)
    field =
      theme.theme_fields.find_by(
        target_id: Theme.targets[opts.fetch(:target)],
        name: opts.fetch(:name),
      ) if opts
    [path, field]
  end
snapshot = {
  settings:
    %w[
      discourse_ai_enabled
      ai_bot_enabled
      ai_forum_assistant_enabled
      ai_forum_assistant_restrict_members
    ].to_h { |name| [name, SiteSetting.public_send(name)] },
  fields:
    fields.to_h do |path, field|
      [
        path,
        field &&
          { id: field.id, value: field.value, sha256: Digest::SHA256.hexdigest(field.value) },
      ]
    end,
  all_hashes: theme.theme_fields.to_h { |field| [field.id, Digest::SHA256.hexdigest(field.value)] },
}

if input.fetch("mode") == "capture"
  puts snapshot.to_json
  exit
end
abort "Unknown mode" unless input["mode"] == "apply"

theme.transaction do
  paths.each do |path|
    opts = ThemeField.opts_from_file_path(path)
    abort "Unsupported theme path" unless opts
    field = fields.fetch(path)
    value = File.read("/workspace/external/active-theme/#{path}")
    if path.start_with?("locales/")
      locale = File.basename(path, ".yml")
      stored = field ? YAML.safe_load(field.value) : {}
      added = YAML.safe_load(value).dig(locale, "isbf_v2", "workbench_ai_assistant")
      stored[locale] ||= {}
      stored[locale]["isbf_v2"] ||= {}
      stored[locale]["isbf_v2"]["workbench_ai_assistant"] = added
      value = stored.to_yaml
    elsif field && field.value != value
      expected = input.fetch("expected_hashes").fetch(path)
      unless Digest::SHA256.hexdigest(field.value) == expected
        abort "Concurrent theme changes for #{path}"
      end
    end
    theme.set_field(**opts.merge(value: value))
  end
  theme.save!
  SiteSetting.discourse_ai_enabled = true
end

after_hashes =
  theme.reload.theme_fields.to_h { |field| [field.id, Digest::SHA256.hexdigest(field.value)] }
changed = after_hashes.select { |id, hash| snapshot.fetch(:all_hashes)[id] != hash }.keys
errors = theme.theme_fields.where(id: changed).where.not(error: [nil, ""]).pluck(:id, :error)
abort "Theme compile errors: #{errors.to_json}" if errors.any?
puts(
  {
    updated_field_ids: changed,
    preserved_fields: after_hashes.keys.length - changed.length,
    assistant_enabled: SiteSetting.ai_forum_assistant_enabled,
    model_count: LlmModel.count,
  }.to_json,
)
