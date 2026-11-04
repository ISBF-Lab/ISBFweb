# frozen_string_literal: true

module ActivityLevelsSpecHelpers
  def activity_condition(metric, value, period: "all_time", **options)
    { "metric" => metric, "period" => period, "value" => value }.merge(options.stringify_keys)
  end

  def activity_tier(
    identifier:,
    conditions:,
    name: "",
    continuous_days: 0,
    gap_hours: 36,
    buffer: 0,
    period_days: 100
  )
    {
      "id" => identifier,
      "name" => name,
      "period_days" => period_days,
      "continuous_days" => continuous_days,
      "max_check_gap_hours" => gap_hours,
      "demotion_buffer_percent" => buffer,
      "conditions" => conditions,
    }
  end

  def activity_rules(levels:, allow_demotion: true, revision: 0)
    base = activity_tier(identifier: "legacy-0", conditions: [])
    { "revision" => revision, "allow_demotion" => allow_demotion, "levels" => [base, *levels] }
  end

  def persist_activity_rules(document)
    previous = DiscourseAcademyRoles::ActivityLevels::Configuration.current
    deleted =
      previous.levels.map { |level| level["id"] } -
        document.fetch("levels").map { |level| level["id"] }
    DiscourseAcademyRoles::ActivityLevels::Configuration.save!(
      DiscourseAcademyRoles::ActivityLevels::Configuration.new(document),
      expected_revision: previous.revision,
      confirmed_deleted_ids: deleted,
    )
  end

  def assign_activity_level(user, identifier:, number:)
    user.reload
    user.custom_fields[DiscourseAcademyRoles::ActivityLevels::LEVEL_ID_FIELD] = identifier
    user.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD] = number
    user.save_custom_fields
    reset_activity_appearance_caches
  end

  def activity_cosmetics(avatar_minimum: "legacy-0", name_minimum: "legacy-0", enabled: true)
    DiscourseAcademyRoles::ActivityLevels::Cosmetics.defaults.merge(
      "avatar_minimum_level_id" => avatar_minimum,
      "name_color_enabled" => enabled,
      "name_color_minimum_level_id" => name_minimum,
      "name_color_light" => "#a51b81",
      "name_color_dark" => "#f67cda",
    )
  end

  def reset_activity_appearance_caches
    DiscourseAcademyRoles::ActivityLevels::Current.reset
    DiscourseAcademyRoles::ActivityLevels::Cosmetics::Cache.reset
    DiscourseAcademyRoles::NameColor::Cache.reset
    DiscourseAvatarFrames::Cache.reset
  end
end
