# frozen_string_literal: true

require "digest"
require "json"

raise "Development environment required" unless Rails.env.development?
unless ActiveRecord::Base.connection_db_config.database == "discourse_development"
  raise "Unexpected database"
end
raise "Protection plugin required" unless defined?(IsbfModeration::Hold)

# Never remove this plugin while held content exists.
SiteSetting.isbf_severe_reports_enabled = false
fields_path, manifest_path = ARGV
original = JSON.parse(File.read(fields_path))
manifest = JSON.parse(File.read(manifest_path), symbolize_names: true)
keys = manifest.map { |field| [field.fetch(:target_id), field.fetch(:name)] }
raise "Unexpected restoration scope" unless keys.length == 9 && keys.uniq.length == 9

Theme.transaction do
  theme = Theme.lock.find(4)
  unless theme.name == "ISBF Campus Feed" && SiteSetting.default_theme_id == 4
    raise "Unexpected theme"
  end
  before = theme.theme_fields.order(:target_id, :name).pluck(:target_id, :name, :value)
  manifest.each do |entry|
    key = [entry.fetch(:target_id), entry.fetch(:name)]
    field = theme.theme_fields.find_by(target_id: key.first, name: key.last)
    unless field && Digest::SHA256.hexdigest(field.value.delete("\r")) == entry.fetch(:sha256)
      raise "Deployed field changed; manual reconciliation required"
    end
    prior = original.find { |target, name, _| [target, name] == key }
    if prior
      theme.set_field(target: Theme.targets[key.first], name: key.last, value: prior.last)
    else
      field.destroy!
    end
  end
  theme.save!
  theme.reload
  raise "Theme compilation failed" if theme.theme_fields.where.not(error: [nil, ""]).exists?
  after = theme.theme_fields.order(:target_id, :name).pluck(:target_id, :name, :value)
  unless after.reject { |target, name, _| keys.include?([target, name]) } ==
           before.reject { |target, name, _| keys.include?([target, name]) }
    raise "Unrelated theme fields changed"
  end
end
puts JSON.generate(
       submissions_enabled: false,
       protection_retained: true,
       restored_theme_fields: keys,
     )
