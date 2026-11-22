# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    class EntryPoint
      def inject_into(plugin)
        plugin.on(:before_create_post) do |post, options|
          Policy.ensure_options_available!(options)
          if Policy.pending_question?(options)
            # New-topic body validation runs before the Topic association exists.
            post.instance_variable_set(:@forum_assistant_question, true)
          end
        end

        plugin.on(:site_setting_changed) do |name, _old_value, new_value|
          if name == :ai_forum_assistant_enabled && new_value
            SiteSetting.ai_forum_assistant_restrict_members = true
          end
        end

        plugin.add_model_callback(:post, :before_create) do
          if Policy.applies_to_post?(self)
            begin
              @ai_forum_assistant_request = AiForumAssistantRequest.admit!(user: user, post: self)
            rescue Policy::Rejected, RateLimiter::LimitExceeded => error
              errors.add(:base, error.message)
              throw :abort
            end
          end
        end

        plugin.add_model_callback(:post, :after_create) do
          @ai_forum_assistant_request&.update!(post_id: id)
        end

        plugin.add_model_callback(:post, :after_rollback) do
          if @ai_forum_assistant_request
            Throttle.release(user_id, @ai_forum_assistant_request.request_uuid)
          end
        end

        plugin.add_to_serializer(
          :current_user,
          :forum_assistant,
          include_condition: -> { scope.authenticated? },
        ) { Status.new(scope.user).as_json }

        plugin.add_to_serializer(
          :topic_view,
          :is_forum_assistant,
          include_condition: -> { object.topic.private_message? },
        ) { Policy.managed_topic?(object.topic) }

        plugin.add_to_serializer(
          :topic_view,
          :forum_assistant_read_only,
          include_condition: -> { object.topic.private_message? },
        ) do
          Configuration.restricted?(scope.user) && Policy.ai_topic?(object.topic) &&
            !Policy.authorized_conversation?(object.topic, scope.user)
        end
      end
    end
  end
end
