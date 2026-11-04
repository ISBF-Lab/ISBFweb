# frozen_string_literal: true

module DiscourseAcademyRoles::ActivityLevels
  class Metrics
    def initialize(user, now: Time.current, totals: {})
      @user = user
      @now = now
      @totals = totals
      @values = {}
    end

    def condition_met?(condition, level, buffer: 0)
      key = condition["metric"]
      definition = Catalog::DEFINITIONS.fetch(key)
      days = condition["period"] == "recent" ? level["period_days"] : nil
      threshold = condition["value"]
      if definition[:percentage]
        count_key = key == "topics_viewed_percent" ? "topics_entered" : "posts_read"
        threshold = [(total(count_key, days) * threshold / 100.0).round, condition["cap"]].min
        actual = value(count_key, days)
      else
        actual = value(key, days, months: condition["months"])
      end
      if definition[:maximum]
        actual <= threshold
      else
        threshold *= (100 - buffer) / 100.0 if days && !definition[:maximum]
        actual >= threshold &&
          (key != "time_read_minutes" || (@now - @user.created_at) / 60 >= threshold)
      end
    end

    def value(key, days, months: nil)
      @values.fetch([key, days, months]) do
        @values[[key, days, months]] = calculate(key, days, months)
      end
    end

    private

    def calculate(key, days, months)
      case key
      when "topics_entered"
        days ? topic_views.where("viewed_at > ?", since(days)).count : stat.topics_entered
      when "posts_read"
        days ? visits(days).sum(:posts_read) : stat.posts_read_count
      when "time_read_minutes"
        (days ? visits(days).sum(:time_read) : stat.time_read) / 60
      when "days_visited"
        days ? visits(days).where("posts_read > 0").count : stat.days_visited
      when "topics_replied_to"
        stat.calc_topic_reply_count!(days ? since(days) : nil)
      when "likes_given"
        days ? likes(UserAction::LIKE, days).count : stat.likes_given
      when "likes_received"
        days ? likes(UserAction::WAS_LIKED, days).count : stat.likes_received
      when "likes_received_users"
        likes(UserAction::WAS_LIKED, days).distinct.count(:acting_user_id)
      when "likes_received_days"
        likes(UserAction::WAS_LIKED, days).distinct.count(Arel.sql("DATE(user_actions.created_at)"))
      when "topics_viewed_all_time"
        topic_views.count
      when "posts_read_all_time"
        @user.user_visits.sum(:posts_read)
      when "flagged_posts"
        agreed_flags(days).distinct.count(:post_id)
      when "flagged_by_users"
        agreed_flags(days).distinct.count(:user_id)
      when "penalty_count"
        penalty_count(months)
      end
    end

    def stat
      @user.user_stat
    end

    def since(days)
      @now - days.days
    end

    def visits(days)
      @user.user_visits.where("visited_at > ?", since(days))
    end

    def topic_views
      TopicViewItem
        .where(user_id: @user.id)
        .joins(:topic)
        .where.not(topics: { archetype: Archetype.private_message })
    end

    def likes(type, days)
      relation =
        UserAction
          .where(user_id: @user.id, action_type: type)
          .joins(:target_topic)
          .where.not(topics: { archetype: Archetype.private_message })
      relation = relation.where("user_actions.created_at > ?", since(days)) if days
      relation
    end

    def agreed_flags(days)
      flagged =
        @user
          .posts
          .with_deleted
          .where("created_at > ? AND (spam_count > 0 OR inappropriate_count > 0)", since(days))
          .select(:id)
      PostAction
        .with_deleted
        .where(post_id: flagged)
        .where.not(user_id: @user.id)
        .where.not(agreed_at: nil)
    end

    def total(key, days)
      @totals.fetch([key, days]) do
        @totals[[key, days]] = if key == "topics_entered"
          Topic.listable_topics.visible.created_since(since(days)).count
        else
          Post.public_posts.visible.created_since(since(days)).count
        end
      end
    end

    def penalty_count(months)
      rows =
        UserHistory.where(target_user_id: @user.id).where("created_at > ?", @now - months.months)
      counts =
        %i[silence_user suspend_user].map do |action|
          reverse = action == :silence_user ? :unsilence_user : :unsuspend_user
          issued = rows.where(action: UserHistory.actions[action]).count
          reversed =
            rows
              .where(action: UserHistory.actions[reverse])
              .where.not(acting_user_id: Discourse.system_user.id)
              .count
          current = action == :silence_user ? @user.silenced? : @user.suspended?
          [issued - reversed, current ? 1 : 0].max
        end
      counts.sum
    end
  end
end
