# frozen_string_literal: true

module DiscourseAcademyRoles::Admin
  class ActivityLevelsController < ::Admin::AdminController
    requires_plugin DiscourseAcademyRoles::PLUGIN_NAME
    before_action :ensure_developer
    before_action :rate_limit_changes, only: %i[update recalculate]

    def show
      render_json_dump(
        DiscourseAcademyRoles::ActivityLevelConfigurationSerializer.new(
          DiscourseAcademyRoles::ActivityLevels::Configuration.current,
          root: false,
        ).as_json,
      )
    end

    def update
      DiscourseAcademyRoles::ActivityLevels::SaveConfiguration.call(service_params) do
        on_success do |configuration:|
          render_json_dump(
            DiscourseAcademyRoles::ActivityLevelConfigurationSerializer.new(
              configuration,
              root: false,
            ).as_json,
          )
        end
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages, status: 422)
        end
        on_exceptions(DiscourseAcademyRoles::ActivityLevels::Conflict) do
          render_json_error(I18n.t("academy_roles.activity_levels.conflict"), status: 409)
        end
        on_exceptions(DiscourseAcademyRoles::ActivityLevels::UnconfirmedDeletion) do
          render_json_error(
            I18n.t("academy_roles.activity_levels.unconfirmed_deletion"),
            status: 422,
          )
        end
        on_exceptions(DiscourseAcademyRoles::ActivityLevels::ReferencedLevel) do |exception|
          render_json_error(exception.message, status: 422)
        end
        on_failure do
          render_json_error(I18n.t("academy_roles.activity_levels.save_failed"), status: 422)
        end
      end
    end

    def status
      state = DiscourseAcademyRoles::ActivityLevels::Recalculation.current
      render_json_dump(
        recalculation:
          (
            if state
              DiscourseAcademyRoles::ActivityLevelRecalculationSerializer.new(
                state,
                root: false,
              ).as_json
            else
              nil
            end
          ),
      )
    end

    def deletion_impact
      configuration = DiscourseAcademyRoles::ActivityLevels::Configuration.current
      identifier = params.require(:level_id)
      unless configuration.levels.any? { |level| level["id"] == identifier }
        raise Discourse::NotFound
      end

      render_json_dump(
        revision: configuration.revision,
        level_id: identifier,
        assigned_users: configuration.assigned_counts.fetch(identifier, 0),
        references: configuration.references_for(identifier),
      )
    end

    def recalculate
      DiscourseAcademyRoles::ActivityLevels::RetryRecalculation.call(service_params) do
        on_success do |recalculation:|
          render_json_dump(
            {
              recalculation:
                DiscourseAcademyRoles::ActivityLevelRecalculationSerializer.new(
                  recalculation,
                  root: false,
                ).as_json,
            },
            status: 202,
          )
        end
        on_failed_policy(:can_manage) { raise Discourse::InvalidAccess }
        on_failed_policy(:rules_initialized) do
          render_json_error(I18n.t("academy_roles.activity_levels.initialize_first"), status: 422)
        end
      end
    end

    private

    def ensure_developer
      raise Discourse::InvalidAccess unless current_user&.admin?
    end

    def rate_limit_changes
      RateLimiter.new(current_user, "academy-activity-levels-update", 20, 1.minute).performed!
    end
  end
end
