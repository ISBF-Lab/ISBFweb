# frozen_string_literal: true

require "securerandom"
require "digest"

module DiscourseAcademyRoles::ActivityLevels
  class Configuration
    include ActiveModel::Model

    LEVEL_KEYS = %w[
      id
      name
      period_days
      continuous_days
      max_check_gap_hours
      demotion_buffer_percent
      conditions
      badge_id
    ].freeze

    attr_reader :document

    validate :validate_document

    def initialize(document)
      @document = document.deep_stringify_keys.deep_dup
      @document["cosmetics"] = Cosmetics.defaults unless @document.key?("cosmetics")
    end

    def self.current
      new(DiscourseAcademyRoles::ActivityLevels.read(CONFIG_KEY) || defaults)
    end

    def self.persisted?
      PluginStoreRow.exists?(plugin_name: DiscourseAcademyRoles::PLUGIN_NAME, key: CONFIG_KEY)
    end

    def self.defaults
      condition = ->(metric, value, period = "all_time", extra = {}) do
        { "metric" => metric, "period" => period, "value" => value }.merge(extra)
      end
      level = ->(number, conditions) do
        {
          "id" => "legacy-#{number}",
          "name" => "",
          "period_days" => SiteSetting.tl3_time_period,
          "continuous_days" => 0,
          "max_check_gap_hours" => 36,
          "demotion_buffer_percent" => number == 3 ? 10 : 0,
          "conditions" => conditions,
        }
      end
      first = [
        condition.call("topics_entered", SiteSetting.tl1_requires_topics_entered),
        condition.call("posts_read", SiteSetting.tl1_requires_read_posts),
        condition.call("time_read_minutes", SiteSetting.tl1_requires_time_spent_mins),
      ]
      second = [
        condition.call("topics_entered", SiteSetting.tl2_requires_topics_entered),
        condition.call("posts_read", SiteSetting.tl2_requires_read_posts),
        condition.call("time_read_minutes", SiteSetting.tl2_requires_time_spent_mins),
        condition.call("days_visited", SiteSetting.tl2_requires_days_visited),
        condition.call("likes_received", SiteSetting.tl2_requires_likes_received),
        condition.call("likes_given", SiteSetting.tl2_requires_likes_given),
        condition.call("topics_replied_to", SiteSetting.tl2_requires_topic_reply_count),
      ]
      third = [
        condition.call("days_visited", SiteSetting.tl3_requires_days_visited, "recent"),
        condition.call("topics_replied_to", SiteSetting.tl3_requires_topics_replied_to, "recent"),
        condition.call(
          "topics_viewed_percent",
          SiteSetting.tl3_requires_topics_viewed,
          "recent",
          "cap" => SiteSetting.tl3_requires_topics_viewed_cap,
        ),
        condition.call(
          "posts_read_percent",
          SiteSetting.tl3_requires_posts_read,
          "recent",
          "cap" => SiteSetting.tl3_requires_posts_read_cap,
        ),
        condition.call("topics_viewed_all_time", SiteSetting.tl3_requires_topics_viewed_all_time),
        condition.call("posts_read_all_time", SiteSetting.tl3_requires_posts_read_all_time),
        condition.call("likes_given", SiteSetting.tl3_requires_likes_given, "recent"),
        condition.call("likes_received", SiteSetting.tl3_requires_likes_received, "recent"),
        condition.call(
          "likes_received_users",
          (SiteSetting.tl3_requires_likes_received / 4.0).ceil,
          "recent",
        ),
        condition.call(
          "likes_received_days",
          [
            (SiteSetting.tl3_requires_likes_received / 3.0).ceil,
            (SiteSetting.tl3_time_period * 0.75).ceil,
          ].min,
          "recent",
        ),
        condition.call("flagged_posts", SiteSetting.tl3_requires_max_flagged, "recent"),
        condition.call("flagged_by_users", SiteSetting.tl3_requires_max_flagged, "recent"),
        condition.call("penalty_count", 0, "recent", "months" => 6),
      ]
      levels = [
        level.call(0, []),
        level.call(1, first),
        level.call(2, second),
        level.call(3, third),
      ]
      fourth = level.call(4, third.deep_dup)
      fourth["continuous_days"] = 90
      levels << fourth
      { "revision" => 0, "allow_demotion" => true, "levels" => levels }
    end

    def levels
      document["levels"]
    end

    def revision
      document["revision"]
    end

    def cosmetics
      document["cosmetics"]
    end

    def references_for(identifier)
      references = []
      %w[avatar_minimum_level_id name_color_minimum_level_id].each do |key|
        if cosmetics[key] == identifier
          references << I18n.t("academy_roles.activity_cosmetics.references.#{key}")
        end
      end
      if defined?(DiscourseAvatarFrames::Frame) &&
           DiscourseAvatarFrames::Frame.column_names.include?("minimum_activity_level_id")
        references.concat(
          DiscourseAvatarFrames::Frame.where(minimum_activity_level_id: identifier).pluck(:name),
        )
      end
      references
    end

    def allow_demotion?
      document["allow_demotion"]
    end

    def id
      CONFIG_KEY
    end

    def fingerprint(level)
      Digest::SHA256.hexdigest(JSON.generate(level.except("id", "name", "badge_id")))
    end

    def self.save!(candidate, expected_revision:, confirmed_deleted_ids:)
      DiscourseAcademyRoles::ActivityLevels.synchronize do
        previous = current
        raise Conflict if previous.revision != expected_revision
        deleted =
          previous.levels.map { |entry| entry["id"] } - candidate.levels.map { |entry| entry["id"] }
        references = deleted.flat_map { |identifier| candidate.references_for(identifier) }.uniq
        if references.present?
          raise ReferencedLevel,
                I18n.t(
                  "academy_roles.activity_cosmetics.referenced_level",
                  references: references.join(", "),
                )
        end
        raise UnconfirmedDeletion unless (deleted - confirmed_deleted_ids).empty?
        backfill_identifiers(previous) unless persisted?
        candidate.document["revision"] = previous.revision + 1
        candidate.levels.each { |entry| entry["id"] ||= SecureRandom.uuid }
        DiscourseAcademyRoles::ActivityLevels.write!(CONFIG_KEY, candidate.document)
        Recalculation.prepare!(candidate)
        Current.reset
        Cosmetics::Cache.reset
        candidate
      end
    end

    def self.backfill_identifiers(configuration)
      User
        .where("id > 0")
        .find_in_batches(batch_size: BATCH_SIZE) do |users|
          fields =
            User.custom_fields_for_ids(
              users.map(&:id),
              [
                LEVEL_ID_FIELD,
                DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD,
                DiscourseAcademyRoles::LV3_SINCE_FIELD,
                DiscourseAcademyRoles::LV3_CHECKED_AT_FIELD,
              ],
            )
          users.each do |user|
            values = fields.fetch(user.id, {})
            if values[LEVEL_ID_FIELD].blank?
              level =
                configuration.levels[values[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD].to_i] ||
                  configuration.levels.first
              user.custom_fields[LEVEL_ID_FIELD] = level["id"]
              user.save_custom_fields
            end
            since = values[DiscourseAcademyRoles::LV3_SINCE_FIELD]
            checked_at = values[DiscourseAcademyRoles::LV3_CHECKED_AT_FIELD]
            if since.present? && checked_at.present? &&
                 !DiscourseAcademyRoles::ActivityLevels.read("#{STATE_PREFIX}#{user.id}")
              legacy_level = configuration.levels.find { |entry| entry["id"] == "legacy-4" }
              DiscourseAcademyRoles::ActivityLevels.write!(
                "#{STATE_PREFIX}#{user.id}",
                {
                  "checks" => {
                    "legacy-4" => {
                      "fingerprint" => configuration.fingerprint(legacy_level),
                      "since" => since,
                      "checked_at" => checked_at,
                    },
                  },
                },
              )
            end
          end
        end
    end

    def assigned_counts
      counts = UserCustomField.where(name: LEVEL_ID_FIELD).group(:value).count
      unless self.class.persisted?
        legacy =
          UserCustomField
            .where(name: DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD)
            .where.not(user_id: UserCustomField.where(name: LEVEL_ID_FIELD).select(:user_id))
            .group(:value)
            .count
        legacy.each do |number, count|
          level = levels[number.to_i] || levels.first
          counts[level["id"]] = counts.fetch(level["id"], 0) + count
        end
      end
      counts
    end

    private

    def validate_document
      unless [true, false].include?(document["allow_demotion"]) && levels.is_a?(Array) &&
               levels.present?
        errors.add(:base, I18n.t("academy_roles.activity_levels.invalid_configuration"))
        return
      end
      identifiers = []
      badge_ids = levels.filter_map { |entry| entry["badge_id"] if entry.is_a?(Hash) }.uniq
      available_badges =
        LevelBadges
          .available
          .where(id: badge_ids.select { |value| Catalog.integer?(value, minimum: 1) })
          .pluck(:id)
      levels.each_with_index do |entry, index|
        valid = entry.is_a?(Hash) && (entry.keys - LEVEL_KEYS).empty?
        if valid
          identifier = entry["id"]
          valid &&=
            identifier.nil? ||
              (identifier.is_a?(String) && identifier.present? && identifier.length <= 64)
          valid &&= entry["name"].is_a?(String) && entry["name"].length <= 80
          valid &&=
            entry["badge_id"].nil? ||
              (entry["badge_id"].is_a?(Integer) && available_badges.include?(entry["badge_id"]))
          valid &&= Catalog.integer?(entry["period_days"], minimum: 1, maximum: 36_500)
          valid &&= Catalog.integer?(entry["continuous_days"], maximum: 36_500)
          valid &&= Catalog.integer?(entry["max_check_gap_hours"], minimum: 1, maximum: 876_000)
          valid &&= Catalog.integer?(entry["demotion_buffer_percent"], maximum: 100)
          conditions = entry["conditions"]
          valid &&=
            conditions.is_a?(Array) && conditions.all? { |item| Catalog.valid_condition?(item) }
          valid &&=
            (
              if index.zero?
                identifier == "legacy-0" && conditions.empty? && entry["continuous_days"].zero?
              else
                conditions.present? || entry["continuous_days"].positive?
              end
            )
          identifiers << identifier if identifier
        end
        unless valid
          errors.add(:base, I18n.t("academy_roles.activity_levels.invalid_level", level: index))
        end
      end
      if identifiers.uniq.length != identifiers.length
        errors.add(:base, I18n.t("academy_roles.activity_levels.duplicate_level"))
      end
      unless Cosmetics.valid?(cosmetics, levels)
        errors.add(:base, I18n.t("academy_roles.activity_cosmetics.invalid_configuration"))
      end
    end
  end
end
