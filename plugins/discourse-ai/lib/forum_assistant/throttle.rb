# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    class Throttle
      RELEASE_SCRIPT = <<~LUA
        if redis.call('get', KEYS[1]) == ARGV[1] then
          return redis.call('del', KEYS[1])
        end
        return 0
      LUA
      VIOLATION_SCRIPT = <<~LUA
        redis.call('zremrangebyscore', KEYS[1], '-inf', ARGV[1])
        redis.call('zadd', KEYS[1], ARGV[2], ARGV[3])
        redis.call('expire', KEYS[1], ARGV[4])
        if redis.call('zcard', KEYS[1]) >= tonumber(ARGV[5]) then
          redis.call('set', KEYS[2], ARGV[6], 'EX', ARGV[7])
          redis.call('del', KEYS[1])
        end
        return 1
      LUA

      def self.lock_key(user_id)
        "ai_forum_assistant:active:#{user_id}"
      end

      def self.cooldown_key(user_id)
        "ai_forum_assistant:cooldown:#{user_id}"
      end

      def self.blocked_until(user_id)
        value = Discourse.redis.get(cooldown_key(user_id))
        Time.zone.at(value.to_i) if value.present?
      end

      def self.active?(user_id)
        Discourse.redis.exists?(lock_key(user_id))
      end

      def self.acquire!(user, request_uuid)
        raise Policy::Rejected.new(:cooldown) if blocked_until(user.id)
        RateLimiter.new(
          user,
          "ai_forum_assistant",
          SiteSetting.ai_forum_assistant_questions_per_minute,
          1.minute,
          apply_limit_to_staff: true,
        ).performed!
        unless Discourse.redis.set(
                 lock_key(user.id),
                 request_uuid,
                 nx: true,
                 ex: SiteSetting.ai_forum_assistant_timeout_seconds,
               )
          raise Policy::Rejected.new(:busy)
        end
      end

      def self.owned?(user_id, request_uuid)
        Discourse.redis.get(lock_key(user_id)) == request_uuid
      end

      def self.release(user_id, request_uuid)
        Discourse.redis.eval(
          RELEASE_SCRIPT,
          keys: [Discourse.redis.namespace_key(lock_key(user_id))],
          argv: [request_uuid],
        )
      end

      def self.record_violation(user_id, request_uuid)
        window = SiteSetting.ai_forum_assistant_violation_window_minutes.minutes.to_i
        cooldown = SiteSetting.ai_forum_assistant_cooldown_minutes.minutes.to_i
        Discourse.redis.eval(
          VIOLATION_SCRIPT,
          keys: [
            Discourse.redis.namespace_key("ai_forum_assistant:violations:#{user_id}"),
            Discourse.redis.namespace_key(cooldown_key(user_id)),
          ],
          argv: [
            Time.current.to_f - window,
            Time.current.to_f,
            request_uuid,
            window,
            SiteSetting.ai_forum_assistant_violation_limit,
            (Time.current + cooldown).to_i,
            cooldown,
          ],
        )
      end

      def self.clear_cooldown(user_id)
        Discourse.redis.del(cooldown_key(user_id), "ai_forum_assistant:violations:#{user_id}")
      end
    end
  end
end
