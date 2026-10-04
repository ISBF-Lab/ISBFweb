# frozen_string_literal: true

module DiscourseAcademyRoles
  class ActivityRequirements < TrustLevel3Requirements
    def trust_level_locked
      false
    end
  end

  class ActivityLevel
    def self.update(user, now: Time.zone.now)
      fields = user.custom_fields
      previous_level = fields[ACTIVITY_LEVEL_FIELD].to_i
      previous_since = fields[LV3_SINCE_FIELD]
      previous_checked_at = fields[LV3_CHECKED_AT_FIELD]
      requirements = ActivityRequirements.new(user)

      if requirements.requirements_met?
        since = Time.zone.parse(fields[LV3_SINCE_FIELD]) if fields[LV3_SINCE_FIELD].present?
        last_check = Time.zone.parse(previous_checked_at) if previous_checked_at.present?
        since = now if since.nil? || last_check.nil? || last_check < now - 36.hours
        level = since <= now - 90.days ? 4 : 3
        fields[LV3_SINCE_FIELD] = since.iso8601
        fields[LV3_CHECKED_AT_FIELD] = now.iso8601
      else
        fields.delete(LV3_SINCE_FIELD)
        fields.delete(LV3_CHECKED_AT_FIELD)
        level =
          if previous_level >= 3 && !requirements.requirements_lost?
            3
          elsif Promotion.tl2_met?(user)
            2
          elsif Promotion.tl1_met?(user)
            1
          else
            0
          end
      end

      if previous_level == level && previous_since == fields[LV3_SINCE_FIELD] &&
           previous_checked_at == fields[LV3_CHECKED_AT_FIELD]
        return
      end

      fields[ACTIVITY_LEVEL_FIELD] = level
      user.save_custom_fields
    end
  end
end
