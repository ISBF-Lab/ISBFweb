# frozen_string_literal: true

module IsbfAnonymous
  class LegacyMigrator
    def initialize(dry_run: true, cleanup: false)
      @dry_run = dry_run
      @cleanup = cleanup
      @report = {
        dry_run: dry_run,
        posts: 0,
        queued_posts: 0,
        cleanable_accounts: [],
        deleted_accounts: [],
        retained_accounts: [],
        skipped_posts: [],
      }
    end

    def run
      if !@dry_run && !SiteSetting.isbf_anonymous_pool_enabled
        raise Discourse::InvalidParameters.new("Enable the anonymous pool before migrating posts")
      end

      DistributedMutex.synchronize("isbf_anonymous_legacy_migration", validity: 1.hour) do
        AnonymousUser.includes(:user, :master_user).find_each { |mapping| migrate_shadow(mapping) }
      end
      @report
    end

    private

    def migrate_shadow(mapping)
      shadow = mapping.user
      master = mapping.master_user
      unless shadow && master
        @report[:retained_accounts] << {
          user_id: mapping.user_id,
          reason: "missing account or owner",
        }
        return
      end

      author = nil
      retained = false
      post_ids = []
      topic_ids = []
      Post
        .with_deleted
        .where(user_id: shadow.id)
        .includes(:_custom_fields, topic: :category)
        .find_each do |post|
          unless migratable_post?(post)
            retained = true
            @report[:skipped_posts] << { id: post.id, reason: "unmarked or non-public post" }
            next
          end

          @report[:posts] += 1
          post_ids << post.id
          topic_ids << post.topic_id if post.is_first_post?
          next if @dry_run

          author ||= pooled_author(mapping)
          migrate_post(post, shadow, master, author)
        end

      ReviewableQueuedPost
        .where(target_created_by_id: shadow.id)
        .find_each do |reviewable|
          unless IsbfAnonymous.requested?(reviewable.payload) && public_reviewable?(reviewable)
            retained = true
            next
          end

          @report[:queued_posts] += 1
          next if @dry_run

          author ||= pooled_author(mapping)
          reviewable.with_lock do
            reviewable.payload[OWNER_FIELD] = master.id
            reviewable.update!(target_created_by: author)
          end
        end

      other_reviewables =
        Reviewable.where(target_created_by_id: shadow.id).where.not(type: "ReviewableQueuedPost")
      other_reviewables =
        other_reviewables.where.not(target_type: "Post", target_id: post_ids) if @dry_run
      retained ||= other_reviewables.exists?
      remaining_topics = Topic.with_deleted.where(user_id: shadow.id)
      remaining_topics = remaining_topics.where.not(id: topic_ids) if @dry_run
      retained ||= remaining_topics.exists?
      retained ||= UserAuthToken.where(user_id: shadow.id).exists?
      retained ||= UserAssociatedAccount.where(user_id: shadow.id).exists?
      retained ||= SingleSignOnRecord.where(user_id: shadow.id).exists?
      retained ||= shadow.staff?

      master.user_stat.update_pending_posts unless @dry_run

      if retained
        @report[:retained_accounts] << {
          user_id: shadow.id,
          reason: "remaining content, review, or login data",
        }
      else
        @report[:cleanable_accounts] << shadow.id
        cleanup_shadow(shadow) if @cleanup && !@dry_run
      end
    end

    def migratable_post?(post)
      post.custom_fields[POST_FIELD] && post.topic && !post.topic.private_message? &&
        !post.topic.category&.read_restricted? && post.topic.visible?
    end

    def public_reviewable?(reviewable)
      topic = reviewable.topic
      return false if reviewable.topic_id && !topic
      return false if topic && (topic.private_message? || !topic.visible?)
      return false if (topic&.category || reviewable.category)&.read_restricted?
      return false if reviewable.payload["visible"].to_s == "false"

      reviewable.payload["archetype"].blank? || reviewable.payload["archetype"] == Archetype.default
    end

    def pooled_author(mapping)
      slot = PoolAccount.slot_for("legacy:#{mapping.user_id}:#{mapping.master_user_id}")
      PoolAccount.for_slot!(slot).user
    end

    def migrate_post(post, shadow, master, author)
      DistributedMutex.synchronize("topic_id_#{post.topic_id}") do
        Post.transaction do
          post.lock!
          return unless post.user_id == shadow.id

          post.custom_fields[OWNER_FIELD] = master.id
          post.save_custom_fields
          previous_editor_id = post.last_editor_id
          previous_updated_at = post.updated_at
          PostOwnerChanger.new(
            post_ids: [post.id],
            topic_id: post.topic_id,
            new_owner: author,
            acting_user: Discourse.system_user,
            skip_revision: true,
          ).change_owner!
          post.update_columns(
            last_editor_id: previous_editor_id == shadow.id ? author.id : previous_editor_id,
            updated_at: previous_updated_at,
          )
          TopicUser.where(user_id: author.id, topic_id: post.topic_id).delete_all
          Reviewable.where(
            target_type: "Post",
            target_id: post.id,
            target_created_by_id: shadow.id,
          ).update_all(target_created_by_id: author.id)
        end
      end
    end

    def cleanup_shadow(shadow)
      shadow.with_lock do
        if Post.with_deleted.exists?(user_id: shadow.id) ||
             Topic.with_deleted.exists?(user_id: shadow.id) ||
             Reviewable.exists?(target_created_by_id: shadow.id) ||
             UserAuthToken.exists?(user_id: shadow.id)
          return
        end

        if UserDestroyer.new(Discourse.system_user).destroy(
             shadow,
             context: "Anonymous account pool migration",
           )
          @report[:deleted_accounts] << shadow.id
        end
      end
    end
  end
end
