# frozen_string_literal: true

module DiscourseAcademyRoles::ActivityLevels
  module Catalog
    DEFINITIONS = {
      "days_visited" => {
        group: "basic",
      },
      "topics_entered" => {
        group: "basic",
      },
      "posts_read" => {
        group: "basic",
      },
      "time_read_minutes" => {
        group: "basic",
      },
      "topics_replied_to" => {
        group: "basic",
      },
      "likes_given" => {
        group: "basic",
      },
      "likes_received" => {
        group: "basic",
      },
      "topics_viewed_all_time" => {
        group: "advanced",
        periods: %w[all_time],
      },
      "posts_read_all_time" => {
        group: "advanced",
        periods: %w[all_time],
      },
      "likes_received_users" => {
        group: "advanced",
      },
      "likes_received_days" => {
        group: "advanced",
      },
      "topics_viewed_percent" => {
        group: "advanced",
        periods: %w[recent],
        percentage: true,
      },
      "posts_read_percent" => {
        group: "advanced",
        periods: %w[recent],
        percentage: true,
      },
      "flagged_posts" => {
        group: "advanced",
        periods: %w[recent],
        maximum: true,
      },
      "flagged_by_users" => {
        group: "advanced",
        periods: %w[recent],
        maximum: true,
      },
      "penalty_count" => {
        group: "advanced",
        periods: %w[recent],
        maximum: true,
        months: true,
      },
    }.freeze

    MAXIMUM_INTEGER = 2_147_483_647

    def self.definitions
      DEFINITIONS.map do |key, definition|
        {
          key: key,
          group: definition[:group],
          periods: definition.fetch(:periods, %w[all_time recent]),
          percentage: definition[:percentage] == true,
          maximum: definition[:maximum] == true,
          months: definition[:months] == true,
        }
      end
    end

    def self.valid_condition?(condition)
      return false unless condition.is_a?(Hash)

      definition = DEFINITIONS[condition["metric"]]
      return false unless definition
      return false unless (condition.keys - %w[metric period value cap months]).empty?
      return false if definition.fetch(:periods, %w[all_time recent]).exclude?(condition["period"])
      unless integer?(condition["value"], maximum: definition[:percentage] ? 100 : MAXIMUM_INTEGER)
        return false
      end
      return false if definition[:percentage] && !integer?(condition["cap"])
      if definition[:months] && !integer?(condition["months"], minimum: 1, maximum: 1200)
        return false
      end
      return false if !definition[:percentage] && condition.key?("cap")
      return false if !definition[:months] && condition.key?("months")

      true
    end

    def self.integer?(value, minimum: 0, maximum: MAXIMUM_INTEGER)
      value.is_a?(Integer) && value.between?(minimum, maximum)
    end
  end
end
