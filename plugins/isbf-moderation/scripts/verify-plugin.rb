# frozen_string_literal: true

raise "Development environment required" unless Rails.env.development?
unless ActiveRecord::Base.connection_db_config.database == "discourse_development"
  raise "Unexpected database"
end
unless Discourse.plugins.any? { |plugin| plugin.metadata.name == "isbf-moderation" }
  raise "Missing plugin"
end
guardian = Guardian.new
capability = SiteSerializer.new(Site.new(guardian), scope: guardian, root: false).as_json
raise "Missing capability" unless capability[:isbf_severe_reports_enabled] == true
raise "Missing translation" unless I18n.exists?("isbf_moderation.severe_label", :en)
raise "Unexpected prior hold" unless PostCustomField.where(name: IsbfModeration::Hold::FIELD).empty?
puts JSON.generate(
       plugin: "isbf-moderation",
       capability: true,
       prior_holds: 0,
       migrations_required: false,
     )
