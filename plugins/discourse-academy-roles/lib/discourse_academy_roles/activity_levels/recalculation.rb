# frozen_string_literal: true

module DiscourseAcademyRoles::ActivityLevels
  module Recalculation
    ACTIVE_STATUSES = %w[queued running].freeze

    def self.current
      DiscourseAcademyRoles::ActivityLevels.read(RUN_KEY)
    end

    def self.prepare!(configuration)
      scope = DiscourseAcademyRoles::ActivityLevels.eligible_accounts
      ceiling = scope.maximum(:id) || 0
      state = {
        "id" => SecureRandom.uuid,
        "revision" => configuration.revision,
        "status" => "queued",
        "processed" => 0,
        "total" => scope.where("users.id <= ?", ceiling).count,
        "upgraded" => 0,
        "downgraded" => 0,
        "unchanged" => 0,
        "failed" => 0,
        "last_user_id" => 0,
        "ceiling_user_id" => ceiling,
        "started_at" => nil,
        "completed_at" => nil,
        "error" => nil,
      }
      DiscourseAcademyRoles::ActivityLevels.write!(RUN_KEY, state)
      state
    end

    def self.enqueue!
      state = current
      Jobs.enqueue(:academy_recalculate_activity_levels, run_id: state.fetch("id"))
      state
    rescue StandardError => error
      DiscourseAcademyRoles::ActivityLevels.synchronize do
        latest = current
        if latest && state && latest["id"] == state["id"]
          latest["status"] = "failed"
          latest["error"] = "enqueue_failed"
          DiscourseAcademyRoles::ActivityLevels.write!(RUN_KEY, latest)
        end
      end
      Rails.logger.error("Activity level enqueue failed: #{error.class}")
      current
    end

    def self.retry!
      DiscourseAcademyRoles::ActivityLevels.synchronize do
        configuration = Configuration.current
        state = current
        prepare!(configuration) unless state && ACTIVE_STATUSES.include?(state["status"])
      end
      enqueue!
    end

    def self.schedule!
      return unless Configuration.persisted?

      enqueue =
        DiscourseAcademyRoles::ActivityLevels.synchronize do
          state = current
          if state && ACTIVE_STATUSES.include?(state["status"])
            true
          else
            prepare!(Configuration.current)
            true
          end
        end
      enqueue! if enqueue
    end

    def self.perform!(run_id)
      totals = {}
      loop do
        state = current
        return unless state && state["id"] == run_id && ACTIVE_STATUSES.include?(state["status"])
        configuration = Configuration.current
        return unless state["revision"] == configuration.revision

        users =
          DiscourseAcademyRoles::ActivityLevels
            .eligible_accounts
            .where(
              "users.id > ? AND users.id <= ?",
              state["last_user_id"],
              state["ceiling_user_id"],
            )
            .order(:id)
            .limit(BATCH_SIZE)
            .to_a
        if users.empty?
          complete!(run_id)
          return
        end
        users.each { |user| process_user!(run_id, user, totals) }
      end
    rescue StandardError => error
      DiscourseAcademyRoles::ActivityLevels.synchronize do
        state = current
        if state && state["id"] == run_id
          state["status"] = "failed"
          state["error"] = "calculation_failed"
          DiscourseAcademyRoles::ActivityLevels.write!(RUN_KEY, state)
        end
      end
      Rails.logger.error("Activity level calculation failed: #{error.class}")
      raise
    end

    def self.process_user!(run_id, user, totals)
      DiscourseAcademyRoles::ActivityLevels.synchronize do
        state = current
        configuration = Configuration.current
        next unless state && state["id"] == run_id && state["revision"] == configuration.revision
        next if state["last_user_id"] >= user.id

        outcome = nil
        begin
          User.transaction(requires_new: true) do
            user.lock!
            outcome = Evaluator.new(user, configuration: configuration, totals: totals).update!
          end
        rescue StandardError => error
          state["failed"] += 1
          Rails.logger.error("Activity level account calculation failed: #{error.class}")
        end
        state["status"] = "running"
        state["started_at"] ||= Time.current.iso8601
        state["processed"] += 1
        state["last_user_id"] = user.id
        if outcome
          counter =
            outcome["direction"].positive? ?
              "upgraded" :
              outcome["direction"].negative? ? "downgraded" : "unchanged"
          state[counter] += 1
        end
        DiscourseAcademyRoles::ActivityLevels.write!(RUN_KEY, state)
      end
    end

    def self.complete!(run_id)
      DiscourseAcademyRoles::ActivityLevels.synchronize do
        state = current
        next unless state && state["id"] == run_id && ACTIVE_STATUSES.include?(state["status"])

        state["status"] = state["failed"].positive? ? "completed_with_errors" : "completed"
        state["completed_at"] = Time.current.iso8601
        DiscourseAcademyRoles::ActivityLevels.write!(RUN_KEY, state)
      end
    end
  end
end
