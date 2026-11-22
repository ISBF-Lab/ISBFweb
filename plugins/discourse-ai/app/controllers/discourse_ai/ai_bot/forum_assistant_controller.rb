# frozen_string_literal: true

module DiscourseAi
  module AiBot
    class ForumAssistantController < ::ApplicationController
      requires_plugin PLUGIN_NAME
      requires_login
      prepend_before_action { DiscourseAi::ForumAssistant::Configuration.ensure_available! }

      def status
        render json: DiscourseAi::ForumAssistant::Status.new(current_user).as_json
      end

      def cancel
        requests =
          AiForumAssistantRequest.where(user_id: current_user.id, status: %w[queued running])
        if params[:conversation_id].present?
          topic =
            DiscourseAi::ForumAssistant::Conversations.find!(current_user, params[:conversation_id])
          requests = requests.where(post_id: topic.posts.select(:id))
        end
        requests.find_each { |request| request.finish!("cancelled") }
        head :no_content
      end
    end
  end
end
