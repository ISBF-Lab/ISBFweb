# frozen_string_literal: true

module IsbfNotifications
  class GroupedNotifications
    MENTION_TYPES = %i[mentioned group_mentioned replied reaction].freeze
    GROUP_SQL =
      "CASE WHEN notifications.topic_id IS NULL THEN 'notification-' || notifications.id::text ELSE 'topic-' || notifications.topic_id::text END"
    ACTOR_KEYS = %i[
      username
      display_username
      mentioned_by_username
      invited_by_username
      original_username
    ].freeze

    def initialize(user, guardian, tab: "all")
      raise Discourse::InvalidParameters.new(:tab) if %w[all mentions].exclude?(tab)
      @user = user
      @guardian = guardian
      @tab = tab
      @types = Notification.types.to_h.invert
    end

    def groups(cursor: nil, limit: 20)
      selection =
        scope.select(
          "#{GROUP_SQL} AS group_key, MAX(notifications.created_at) AS latest_at, MAX(notifications.id) AS latest_id",
        ).group(GROUP_SQL)
      if cursor.present?
        boundary = decode_cursor(cursor, "groups")
        selection =
          selection.having(
            "MAX(notifications.created_at) < ? OR (MAX(notifications.created_at) = ? AND MAX(notifications.id) < ?)",
            boundary.fetch("time"),
            boundary.fetch("time"),
            boundary.fetch("id"),
          )
      end
      rows = selection.order(Arel.sql("latest_at DESC, latest_id DESC")).limit(limit + 1).to_a
      more = rows.length > limit
      rows = rows.first(limit)
      topic_ids =
        rows.filter_map do |row|
          row.group_key.delete_prefix("topic-").to_i if row.group_key.start_with?("topic-")
        end
      standalone_ids =
        rows.filter_map do |row|
          if row.group_key.start_with?("notification-")
            row.group_key.delete_prefix("notification-").to_i
          end
        end
      records =
        scope
          .where(topic_id: topic_ids)
          .or(scope.where(id: standalone_ids))
          .includes(:topic)
          .order(created_at: :desc, id: :desc)
          .to_a
      by_topic = records.group_by(&:topic_id)
      actors = actor_summaries(records)
      prepare_users(records, actors.values.flatten)
      groups =
        rows.filter_map do |row|
          if row.group_key.start_with?("notification-")
            record = records.find { |notification| notification.id == row.latest_id }
            next unless record
            {
              key: row.group_key,
              kind: "standalone",
              latest_at: record.created_at,
              unread: !record.read,
              latest: native_entry(record),
            }
          else
            topic_id = row.group_key.delete_prefix("topic-").to_i
            notifications = by_topic.fetch(topic_id, [])
            next if notifications.empty?
            topic = notifications.first.topic
            actions =
              notifications
                .group_by { |notification| action_name(notification) }
                .map do |action, items|
                  actor = actors.fetch(action, []).find { |item| item.topic_id == topic_id }
                  latest = actor ? actor_entry(actor, action, items) : native_entry(items.first)
                  {
                    key: action,
                    count: actor ? actor.total.to_i : items.length,
                    unread: items.any? { |item| !item.read },
                    latest: latest,
                    detail_url: "/isbf/notifications/groups/#{topic_id}/actions/#{action}.json",
                  }
                end
                .sort_by { |action| action[:latest][:created_at] }
                .reverse
            {
              key: row.group_key,
              kind: "topic",
              topic: {
                id: topic.id,
                title: topic.title,
                slug: topic.slug,
                url: topic.url,
              },
              latest_at: row.latest_at,
              unread: notifications.any? { |item| !item.read },
              actions: actions,
            }
          end
        end
      boundary = rows.last
      {
        groups: groups,
        next_cursor:
          (
            if more && boundary
              encode_cursor(
                "groups",
                time: boundary.latest_at.iso8601(6),
                id: boundary.latest_id.to_i,
              )
            else
              nil
            end
          ),
      }
    end

    def details(topic_id:, action:, cursor: nil, limit: 20)
      records =
        scope.where(topic_id: topic_id).includes(:topic).order(created_at: :desc, id: :desc).to_a
      records.select! { |notification| action_name(notification) == action }
      raise Discourse::NotFound if records.empty?
      purpose = "details-#{topic_id}-#{action}"
      offset = cursor.present? ? decode_cursor(cursor, purpose).fetch("offset") : 0
      actor_rows = actors_for(records, action, offset: offset, limit: limit + 1)
      if actor_rows.present?
        more = actor_rows.length > limit
        actor_rows = actor_rows.first(limit)
        prepare_users(records, actor_rows)
        entries = actor_rows.map { |actor| actor_entry(actor, action, records) }
      else
        # Deleted actions and older summaries retain their native navigation.
        prepare_users(records, [])
        page = records.slice(offset, limit + 1) || []
        more = page.length > limit
        entries = page.first(limit).map { |notification| native_entry(notification) }
      end
      { entries: entries, next_cursor: more ? encode_cursor(purpose, offset: offset + limit) : nil }
    end

    private

    def scope
      @scope ||=
        begin
          notifications = Notification.where(user_id: @user.id).visible
          notifications =
            notifications.where(
              notification_type: MENTION_TYPES.filter_map { |type| Notification.types[type] },
            ) if @tab == "mentions"
          notifications =
            notifications.where.not(
              notification_type: Notification.types[:granted_badge],
            ) unless SiteSetting.enable_badges
          topic_ids = notifications.distinct.pluck(:topic_id).compact
          visible_ids = @guardian.can_see_topic_ids(topic_ids: topic_ids)
          notifications =
            notifications.where(topic_id: nil).or(notifications.where(topic_id: visible_ids))
          posts =
            Post
              .with_deleted
              .where(
                "EXISTS (SELECT 1 FROM notifications WHERE notifications.id IN (#{notifications.select(:id).to_sql}) AND notifications.topic_id = posts.topic_id AND notifications.post_number = posts.post_number)",
              )
              .select(
                :id,
                :topic_id,
                :post_number,
                :user_id,
                :post_type,
                :hidden,
                :deleted_at,
                :deleted_by_id,
              )
              .includes(topic: :category)
              .to_a
          @posts =
            posts
              .select { |post| @guardian.can_see_post?(post) }
              .index_by { |post| [post.topic_id, post.post_number] }
          ids =
            notifications
              .pluck(:id, :topic_id, :post_number)
              .filter_map do |id, topic_id, post_number|
                if topic_id.nil? || post_number.nil? || post_number <= 0 ||
                     @posts.key?([topic_id, post_number])
                  id
                end
              end
          notifications.where(id: ids)
        end
    end

    def action_name(notification)
      type = @types[notification.notification_type].to_s
      return "liked" if type == "liked_consolidated"
      return "mentioned" if type == "group_mentioned"
      type.presence || "custom"
    end

    def actor_summaries(records)
      %w[liked reaction].to_h do |action|
        [action, actors_for(records, action, offset: 0, limit: 1)]
      end
    end

    def actors_for(records, action, offset:, limit:)
      return [] if %w[liked reaction].exclude?(action)
      if action == "reaction" &&
           (!defined?(DiscourseReactions::ReactionUser) || !SiteSetting.discourse_reactions_enabled)
        return []
      end
      sources =
        records
          .select { |notification| notification.topic_id && action_name(notification) == action }
          .group_by { |notification| [notification.topic_id, notification.post_number] }
          .filter_map do |key, items|
            post = @posts[key]
            next unless post
            latest = items.first
            {
              post_id: post.id,
              topic_id: post.topic_id,
              notification_id: latest.id,
              cutoff: latest.created_at.iso8601(6),
            }
          end
      return [] if sources.empty?
      table = action == "liked" ? "post_actions" : "discourse_reactions_reaction_users"
      conditions =
        (
          if action == "liked"
            "AND a.deleted_at IS NULL AND a.post_action_type_id = #{PostActionType::LIKE_POST_ACTION_ID}"
          else
            ""
          end
        )
      DB.query(
        <<~SQL,
        WITH unique_actors AS (
          SELECT DISTINCT ON (s.topic_id, a.user_id)
            s.topic_id, s.notification_id, a.user_id, a.id AS action_id, a.created_at
          FROM #{table} a
          JOIN jsonb_to_recordset(:sources::jsonb) AS s(post_id bigint, topic_id bigint, notification_id bigint, cutoff timestamptz)
            ON a.post_id = s.post_id
          JOIN users u ON u.id = a.user_id
          WHERE a.created_at <= s.cutoff #{conditions}
          ORDER BY s.topic_id, a.user_id, a.created_at DESC, a.id DESC
        ), ranked AS (
          SELECT *, COUNT(*) OVER (PARTITION BY topic_id) AS total,
            ROW_NUMBER() OVER (PARTITION BY topic_id ORDER BY created_at DESC, action_id DESC) AS position
          FROM unique_actors
        )
        SELECT * FROM ranked WHERE position BETWEEN :first_position AND :last_position
        ORDER BY topic_id, position
      SQL
        sources: sources.to_json,
        first_position: offset + 1,
        last_position: offset + limit,
      )
    end

    def prepare_users(records, actor_rows)
      usernames = records.filter_map { |notification| acting_username(notification) }
      @users =
        User.where(id: actor_rows.map(&:user_id)).or(User.where(username_lower: usernames)).to_a
      @users_by_id = @users.index_by(&:id)
      @users_by_name = @users.index_by(&:username_lower)
    end

    def acting_username(notification)
      ACTOR_KEYS.filter_map { |key| notification.data_hash[key].presence }.first&.downcase
    end

    def native_entry(notification)
      actor = @users_by_name[acting_username(notification)]
      notification.acting_user = actor
      {
        key: "notification-#{notification.id}",
        action: action_name(notification),
        created_at: notification.created_at,
        actor: actor_json(actor),
        notification:
          NotificationSerializer.new(notification, scope: @guardian, root: false).as_json,
      }
    end

    def actor_entry(actor, action, records)
      notification = records.find { |item| item.id == actor.notification_id } || records.first
      entry = native_entry(notification)
      entry.merge(
        key: "#{action}-#{actor.user_id}",
        created_at: actor.created_at,
        actor: actor_json(@users_by_id[actor.user_id]),
      )
    end

    def actor_json(user)
      return nil unless user
      {
        id: user.id,
        username: user.username,
        name: SiteSetting.enable_names ? user.name : nil,
        avatar_template: user.avatar_template,
      }
    end

    def verifier
      Rails.application.message_verifier("isbf-notifications-pagination")
    end

    def encode_cursor(purpose, **values)
      verifier.generate(values.merge(user_id: @user.id, tab: @tab), purpose: purpose)
    end

    def decode_cursor(cursor, purpose)
      values = verifier.verified(cursor, purpose: purpose)&.stringify_keys
      unless values && values["user_id"] == @user.id && values["tab"] == @tab
        raise Discourse::InvalidParameters.new(:cursor)
      end
      offset = values["offset"]
      if offset && (!offset.is_a?(Integer) || offset.negative?)
        raise Discourse::InvalidParameters.new(:cursor)
      end
      values
    rescue ArgumentError
      raise Discourse::InvalidParameters.new(:cursor)
    end
  end
end
