# frozen_string_literal: true

module IsbfModeration
  module Notifications
    CHANNEL = "/isbf/moderation/posts"
    KEY = :isbf_moderation_defer_notifications

    def self.deferred?
      ActiveSupport::IsolatedExecutionState[KEY] == true
    end

    def self.defer
      previous = ActiveSupport::IsolatedExecutionState[KEY]
      ActiveSupport::IsolatedExecutionState[KEY] = true
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[KEY] = previous
    end

    def self.immediate
      previous = ActiveSupport::IsolatedExecutionState[KEY]
      ActiveSupport::IsolatedExecutionState[KEY] = false
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[KEY] = previous
    end

    def self.publish_after_commit(post, hidden:)
      post_id = post.id
      ActiveRecord.after_all_transactions_commit do
        if committed_post = Post.with_deleted.find_by(id: post_id)
          committed_post.publish_message!(
            CHANNEL,
            { post_id: post_id, topic_id: committed_post.topic_id, hidden: hidden },
          )
        end
      end
    end
  end

  module TrackingNotifications
    %i[publish_delete publish_recover].each do |method_name|
      define_method(method_name) do |topic|
        return super(topic) unless Notifications.deferred?

        topic_id = topic.id
        ActiveRecord.after_all_transactions_commit do
          Notifications.immediate do
            if committed_topic = Topic.with_deleted.find_by(id: topic_id)
              public_send(method_name, committed_topic)
            end
          end
        end
      end
    end
  end

  module TopicUserNotifications
    def notification_level_change(user_id, topic_id, notification_level, reason_id)
      return super unless Notifications.deferred?

      ActiveRecord.after_all_transactions_commit do
        Notifications.immediate do
          notification_level_change(user_id, topic_id, notification_level, reason_id)
        end
      end
    end
  end

  module HoldSystemMessageNotifications
    def enqueue_in(delay, job_name, arguments = {})
      unless Notifications.deferred? && job_name == :send_system_message &&
               arguments[:message_type] == "isbf_severe_post_hidden"
        return super
      end

      captured_arguments = arguments.deep_dup
      ActiveRecord.after_all_transactions_commit do
        Notifications.immediate { enqueue_in(delay, job_name, captured_arguments) }
      end
    end
  end
end
