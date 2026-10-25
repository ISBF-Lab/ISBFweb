# frozen_string_literal: true

module DiscourseAcademyRoles::OfficialPostQuota
  STORE_KEY_PREFIX = "official_post_quota"
  TIME_ZONE = "Asia/Shanghai"
  MAX_LIMIT = 2_147_483_647
  AUDIT_ACTION = "academy_official_weekly_topic_limit_changed"

  def self.snapshot(user, now: Time.current)
    starts_at, resets_at = week_bounds(now)
    limit = limit_for(user)
    used = usage(user, now: now)
    exempt = user.admin?

    {
      limit: limit,
      used: used,
      remaining: limit.zero? || exempt ? nil : [limit - used, 0].max,
      week_starts_at: starts_at.utc.iso8601,
      resets_at: resets_at.utc.iso8601,
      timezone: TIME_ZONE,
      exempt: exempt,
      official: DiscourseAcademyRoles.official_member?(user),
    }
  end

  def self.usage(user, now: Time.current)
    starts_at, resets_at = week_bounds(now)
    counter = load_state(user)["usage"]

    if counter.is_a?(Hash) && counter["week_starts_at"] == starts_at.utc.iso8601 &&
         counter["used"].is_a?(Integer) && counter["used"] >= 0
      return counter["used"]
    end

    historical_usage(user, starts_at, resets_at)
  end

  def self.limited?(user, used)
    limit = limit_for(user)
    !user.admin? && limit.positive? && used >= limit
  end

  # The publisher holds the user row lock inside the post transaction. This runs
  # after the post succeeds so rollback also rolls back the counter.
  def self.record_success!(user, used:, now: Time.current)
    starts_at, = week_bounds(now)
    state = load_state(user)
    state["usage"] = {
      "week_starts_at" => starts_at.utc.iso8601,
      "used" => used + 1,
    }
    save_state!(user, state)
  end

  def self.error_message(user, now: Time.current)
    _, resets_at = week_bounds(now)
    I18n.t(
      "academy_roles.official_post_quota.exceeded",
      limit: limit_for(user),
      resets_at: resets_at.strftime("%Y-%m-%d %H:%M"),
      timezone: TIME_ZONE,
    )
  end

  def self.update_limit!(actor, target, limit:)
    raise Discourse::InvalidAccess unless actor&.admin?
    unless limit.is_a?(Integer) && limit.between?(0, MAX_LIMIT)
      raise Discourse::InvalidParameters,
            I18n.t("academy_roles.official_post_quota.invalid_limit")
    end

    target.with_lock do
      now = Time.current
      state = load_state(target)
      previous_limit = state["limit"].to_i
      starts_at, = week_bounds(now)
      updated_state = state.merge(
        "limit" => limit,
        "usage" => { "week_starts_at" => starts_at.utc.iso8601, "used" => usage(target, now: now) },
      )
      save_state!(target, updated_state) if updated_state != state
      if previous_limit != limit
        StaffActionLogger
          .new(actor)
          .log_custom(
            AUDIT_ACTION,
            subject: target.username,
            previous_value: previous_limit.to_s,
            new_value: limit.to_s,
          )
          .update!(target_user_id: target.id)
      end
      snapshot(target, now: now)
    end
  end

  def self.limit_for(user)
    load_state(user)["limit"].to_i
  end
  private_class_method :limit_for

  def self.load_state(user)
    { "limit" => 0, "usage" => nil }.merge(
      PluginStore.get(DiscourseAcademyRoles::PLUGIN_NAME, "#{STORE_KEY_PREFIX}:#{user.id}") || {},
    )
  end
  private_class_method :load_state

  def self.save_state!(user, state)
    unless PluginStore.set(
             DiscourseAcademyRoles::PLUGIN_NAME,
             "#{STORE_KEY_PREFIX}:#{user.id}",
             state,
           )
      raise ActiveRecord::RecordNotSaved, "Could not save official post quota"
    end
  end
  private_class_method :save_state!

  def self.week_bounds(now)
    starts_at = now.in_time_zone(TIME_ZONE).beginning_of_week(:monday)
    [starts_at, starts_at + 1.week]
  end
  private_class_method :week_bounds

  def self.historical_usage(user, starts_at, resets_at)
    Post
      .with_deleted
      .where(user_id: user.id, post_number: 1, created_at: starts_at...resets_at)
      .where.not(topic_id: SharedDraft.select(:topic_id))
      .where(
        id:
          PostCustomField
            .where(name: DiscourseAcademyRoles::OFFICIAL_POST_FIELD, value: "t")
            .select(:post_id),
      )
      .count
  end
  private_class_method :historical_usage
end
