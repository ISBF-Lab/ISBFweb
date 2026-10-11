# frozen_string_literal: true
ENV["PGPORT"] = "15431"
ENV["DISCOURSE_DB_PORT"] = "15431"
ENV["PGHOST"] = "127.0.0.1"
ENV["DISCOURSE_DB_HOST"] = "127.0.0.1"
ENV["DISCOURSE_DB_SOCKET"] = ""
ENV["DISCOURSE_REDIS_HOST"] = "127.0.0.1"
ENV["DISCOURSE_REDIS_PORT"] = "16431"
ENV["RAILS_DB"] = ENV.fetch(
  "ISBF_PERMISSIONS_DATABASE",
  "discourse_test_admin_permissions_20261011",
)
ENV["DISCOURSE_DEV_DB"] = "discourse_admin_permissions_preview_20261011"
ENV.delete("LOGSTASH_UNICORN_URI")
require "bundler/setup"
require "active_support"
ActiveSupport.on_load(:after_initialize) do
  if %w[
       discourse_test_admin_permissions_20261011
       discourse_admin_permissions_qunit_20261011
       discourse_admin_permissions_preview_20261011
     ].exclude?(ActiveRecord::Base.connection_db_config.database)
    raise "Unexpected database"
  end
  unless ActiveRecord::Base.connection.select_value("SELECT inet_server_port()").to_i == 15_431
    raise "Unexpected PostgreSQL port"
  end
  AssetProcessor.timeout = 120_000
end
