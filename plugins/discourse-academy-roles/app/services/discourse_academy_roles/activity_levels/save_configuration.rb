# frozen_string_literal: true

module DiscourseAcademyRoles::ActivityLevels
  class SaveConfiguration
    include Service::Base

    params do
      attribute :revision
      attribute :allow_demotion
      attribute :levels
      attribute :cosmetics, default: -> { Configuration.current.cosmetics.deep_dup }
      attribute :confirmed_deleted_ids, default: -> { [] }

      validates :revision, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      validate :valid_configuration

      def expected_revision
        revision.to_i if revision.is_a?(Integer) || revision.is_a?(String)
      end

      def normalized_allow_demotion
        case allow_demotion
        when true, "true"
          true
        when false, "false"
          false
        end
      end

      def configuration
        @configuration ||=
          Configuration.new(
            "revision" => expected_revision,
            "allow_demotion" => normalized_allow_demotion,
            "levels" => normalized_levels,
            "cosmetics" => cosmetics,
          )
      end

      def normalized_levels
        return levels unless levels.is_a?(Array)

        previous = Configuration.current.levels.index_by { |entry| entry["id"] }
        levels.map do |entry|
          next entry unless entry.is_a?(Hash)
          value = entry.deep_stringify_keys
          value["badge_id"] = previous[value["id"]]&.dig("badge_id") unless value.key?("badge_id")
          value
        end
      end

      def valid_configuration
        configuration.valid?
        configuration.errors.full_messages.each { |message| errors.add(:base, message) }
        unless confirmed_deleted_ids.is_a?(Array) &&
                 confirmed_deleted_ids.all? { |identifier| identifier.is_a?(String) }
          errors.add(:base, I18n.t("academy_roles.activity_levels.invalid_configuration"))
        end
      end
    end

    policy :can_manage
    model :configuration, :build_configuration
    try Conflict, UnconfirmedDeletion, ReferencedLevel do
      transaction do
        step :persist_configuration
        step :log_change
      end
    end
    step :refresh_caches
    model :recalculation, :enqueue_recalculation

    private

    def can_manage(guardian:)
      guardian.user&.admin? && SiteSetting.academy_roles_enabled?
    end

    def build_configuration(params:)
      params.configuration
    end

    def persist_configuration(params:, configuration:)
      Configuration.save!(
        configuration,
        expected_revision: params.expected_revision,
        confirmed_deleted_ids: params.confirmed_deleted_ids,
      )
    end

    def log_change(guardian:, params:, configuration:)
      StaffActionLogger.new(guardian.user).log_custom(
        "academy_activity_levels_changed",
        previous_value: params.expected_revision.to_s,
        new_value: configuration.revision.to_s,
      )
    end

    def enqueue_recalculation
      Recalculation.enqueue!
    end

    def refresh_caches
      Site.clear_anon_cache!
    end
  end
end
