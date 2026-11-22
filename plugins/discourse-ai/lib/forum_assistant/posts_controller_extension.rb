# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    module PostsControllerExtension
      def self.prepended(controller)
        controller.prepend_before_action(
          :ensure_forum_assistant_workbench_available,
          only: %i[create update destroy recover],
        )
      end

      private

      def ensure_forum_assistant_workbench_available
        return unless Configuration.paused?

        if action_name == "create"
          fields = params[:topic_custom_fields]
          Policy.ensure_options_available!(
            topic_id: params[:topic_id],
            archetype: params[:archetype],
            target_usernames: params[:target_recipients] || params[:target_usernames],
            target_user_ids: params[:target_user_ids],
            custom_fields: fields.is_a?(ActionController::Parameters) ? fields.to_unsafe_h : nil,
          )
        else
          Policy.ensure_options_available!(topic_id: Post.find_by(id: params[:id])&.topic_id)
        end
      end
    end
  end
end
