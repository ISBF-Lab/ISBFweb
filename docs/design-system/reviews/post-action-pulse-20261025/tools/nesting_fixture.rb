# frozen_string_literal: true

require "json"

unless Rails.env.development? && ENV["ISBF_DEV_ENVIRONMENT"] == "1" &&
         ActiveRecord::Base.connection_db_config.database == "discourse_development"
  abort "The nesting fixture requires the isolated development database"
end

case ARGV.fetch(0)
when "read"
when "enable"
  params = JSON.parse(STDIN.read)
  topic = Topic.find(params.fetch("topic_id"))
  abort "Unexpected test topic" unless topic.title == "Development fixture: post action pulse"
  SiteSetting.nested_replies_enabled = true
  SiteSetting.nested_replies_cap_nesting_depth = true
  SiteSetting.nested_replies_max_depth = 1
  NestedTopic.find_or_create_by!(topic: topic)
when "restore"
  values = JSON.parse(STDIN.read)
  SiteSetting.nested_replies_enabled = values.fetch("enabled")
  SiteSetting.nested_replies_cap_nesting_depth = values.fetch("cap")
  SiteSetting.nested_replies_max_depth = values.fetch("depth")
else
  abort "Expected read, enable or restore"
end

puts JSON.generate(
       enabled: SiteSetting.nested_replies_enabled,
       cap: SiteSetting.nested_replies_cap_nesting_depth,
       depth: SiteSetting.nested_replies_max_depth,
     )
