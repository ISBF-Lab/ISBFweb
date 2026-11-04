# frozen_string_literal: true

module DiscourseAcademyRoles::ActivityLevels
  class Evaluator
    def initialize(user, configuration:, now: Time.current, totals: {})
      @user = user
      @configuration = configuration
      @now = now
      @metrics = Metrics.new(user, now: now, totals: totals)
    end

    def update!
      previous_id = @user.custom_fields[LEVEL_ID_FIELD]
      previous_value = @user.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD].to_i
      previous_number = @configuration.levels.index { |entry| entry["id"] == previous_id }
      state = DiscourseAcademyRoles::ActivityLevels.read("#{STATE_PREFIX}#{@user.id}") || {}
      checks = state.fetch("checks", {})
      candidates = [0]

      @configuration.levels.each_with_index do |level, number|
        next if number.zero?
        fingerprint = @configuration.fingerprint(level)
        check = checks[level["id"]]
        check = nil if check && check["fingerprint"] != fingerprint
        complete =
          level["conditions"].all? { |condition| @metrics.condition_met?(condition, level) }
        if complete
          last_check = parse_time(check&.dig("checked_at"))
          since = parse_time(check&.dig("since"))
          since = @now if !since || !last_check ||
            last_check < @now - level["max_check_gap_hours"].hours
          check = {
            "fingerprint" => fingerprint,
            "since" => since.iso8601,
            "checked_at" => @now.iso8601,
          }
          candidates << number if since <= @now - level["continuous_days"].days
        else
          check = nil
          if previous_number && previous_number >= number && level["continuous_days"].zero?
            retained =
              level["conditions"].all? do |condition|
                @metrics.condition_met?(condition, level, buffer: level["demotion_buffer_percent"])
              end
            candidates << number if retained
          end
        end
        checks[level["id"]] = check if level["continuous_days"].positive? && check
        checks.delete(level["id"]) unless level["continuous_days"].positive? && check
      end

      number = candidates.max
      number = [number, previous_number].max if !@configuration.allow_demotion? && previous_number
      selected = @configuration.levels.fetch(number)
      checks.select! do |identifier, _|
        @configuration.levels.any? { |level| level["id"] == identifier }
      end
      @user.custom_fields[LEVEL_ID_FIELD] = selected["id"]
      @user.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD] = number
      @user.save_custom_fields
      LevelBadges.synchronize!(@user, @configuration)
      Cosmetics::Cache.reset
      DiscourseAcademyRoles::NameColor::Cache.reset
      DiscourseAvatarFrames::Cache.reset if defined?(DiscourseAvatarFrames::Cache)
      DiscourseAcademyRoles::ActivityLevels.write!(
        "#{STATE_PREFIX}#{@user.id}",
        { "checks" => checks, "revision" => @configuration.revision },
      )
      comparison = previous_number || previous_value
      { "direction" => number <=> comparison, "changed" => previous_id != selected["id"] }
    end

    private

    def parse_time(value)
      Time.iso8601(value) if value.is_a?(String)
    rescue ArgumentError
      nil
    end
  end
end
