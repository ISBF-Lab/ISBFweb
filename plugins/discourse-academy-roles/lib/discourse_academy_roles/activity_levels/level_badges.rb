# frozen_string_literal: true

module DiscourseAcademyRoles::ActivityLevels
  module LevelBadges
    PREFIX = "activity_levels:badge_grant:"

    def self.available
      Badge.enabled.where(
        system: false,
        multiple_grant: false,
        trigger: Badge::Trigger::None,
        query: [nil, ""],
      )
    end

    def self.synchronize!(user, configuration)
      return unless SiteSetting.enable_badges

      level =
        configuration.levels.find { |entry| entry["id"] == user.custom_fields[LEVEL_ID_FIELD] }
      desired = available.find_by(id: level&.dig("badge_id")) if level&.dig("badge_id")
      key = "#{PREFIX}#{user.id}"
      source = DiscourseAcademyRoles::ActivityLevels.read(key)
      owned = UserBadge.find_by(id: source["user_badge_id"], user_id: user.id) if source
      if owned && owned.badge_id != desired&.id
        BadgeGranter.revoke(owned)
        owned = nil
      end
      PluginStore.remove(DiscourseAcademyRoles::PLUGIN_NAME, key) if source && !owned
      return unless desired
      return if UserBadge.exists?(user_id: user.id, badge_id: desired.id)

      awarded = BadgeGranter.grant(desired, user)
      raise ActiveRecord::RecordNotSaved, "Could not grant activity level badge" unless awarded
      DiscourseAcademyRoles::ActivityLevels.write!(
        key,
        { "user_badge_id" => awarded.id, "badge_id" => desired.id },
      )
    end

    def self.retain_manual!(user_badge)
      key = "#{PREFIX}#{user_badge.user_id}"
      source = DiscourseAcademyRoles::ActivityLevels.read(key)
      if source && source["user_badge_id"] == user_badge.id
        PluginStore.remove(DiscourseAcademyRoles::PLUGIN_NAME, key)
      end
    end

    module ManualGrant
      def grant
        return super unless @granted_by&.id&.positive?

        DiscourseAcademyRoles::ActivityLevels.synchronize do
          result = super
          LevelBadges.retain_manual!(result) if result
          result
        end
      end
    end
  end
end
