# frozen_string_literal: true

require "/workspace/spec/rails_helper"
ENV["LOAD_PLUGINS"] = "1"

Dir["/workspace/spec/fabricators/*.rb"].sort.each { |path| require path }
ENV
  .fetch("ISBF_PASSWORD_SETUP_PLUGINS", "discourse-academy-roles")
  .split(",")
  .each do |plugin|
    Dir["/workspace/plugins/#{plugin}/spec/fabricators/**/*.rb"].sort.each { |path| require path }
  end
