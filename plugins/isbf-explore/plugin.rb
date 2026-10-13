# frozen_string_literal: true

# name: isbf-explore
# about: Stores account-specific preferences for the ISBF Explore feed.
# version: 0.1.0
# authors: ISBF Lab
# url: https://github.com/ISBF-Lab/ISBF-Explore
# required_version: 3.2.0

enabled_site_setting :isbf_explore_enabled

after_initialize do
  require_relative "lib/isbf_explore/category_filter"

  add_filter_custom_filter("isbf-category") do |scope, filter_values, guardian|
    IsbfExplore::CategoryFilter.apply(scope, filter_values, guardian)
  end

  add_to_serializer(
    :site,
    :isbf_explore_category_id_filter,
    include_condition: -> { SiteSetting.isbf_explore_enabled },
  ) { true }

  add_to_serializer(
    :detailed_tag,
    :isbf_explore_filter_name,
    include_condition: -> { SiteSetting.isbf_explore_enabled },
  ) { object.name }

  module ::IsbfExplore
    class Engine < ::Rails::Engine
      engine_name "isbf-explore"
      isolate_namespace IsbfExplore
    end
  end

  require_relative "lib/isbf_explore/preferences"

  class ::IsbfExplore::PreferencesController < ::ApplicationController
    wrap_parameters false
    requires_login
    requires_plugin "isbf-explore"

    def show
      render json: preferences.read
    end

    def update
      allowed_keys = %w[category_ids tag_ids order controller action format]
      unknown_keys = params.keys - allowed_keys
      raise Discourse::InvalidParameters.new(unknown_keys.first) if unknown_keys.present?

      render json: preferences.write(params.slice(:category_ids, :tag_ids, :order).to_unsafe_h)
    end

    private

    def preferences
      IsbfExplore::Preferences.new(current_user, guardian)
    end
  end

  IsbfExplore::Engine.routes.draw do
    get "/preferences" => "preferences#show"
    put "/preferences" => "preferences#update"
  end

  Discourse::Application.routes.append { mount ::IsbfExplore::Engine, at: "/isbf/explore" }
end
