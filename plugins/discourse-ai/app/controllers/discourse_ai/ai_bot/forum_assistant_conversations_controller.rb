# frozen_string_literal: true

module DiscourseAi
  module AiBot
    class ForumAssistantConversationsController < ::ApplicationController
      include AiForumAssistantErrors

      requires_plugin PLUGIN_NAME
      requires_login
      prepend_before_action { DiscourseAi::ForumAssistant::Configuration.ensure_available! }

      def index
        page = Integer(params.fetch(:page, 0), exception: false)
        raise Discourse::InvalidParameters.new(:page) unless page && page.between?(0, 10_000)

        scope =
          DiscourseAi::ForumAssistant::Conversations.for_user(current_user).includes(
            :first_post,
            :topic_allowed_users,
            :topic_allowed_groups,
          )
        starred_query = ConversationStar.where(user_id: current_user.id).select(:topic_id)
        topics =
          scope
            .where.not(id: starred_query)
            .order(last_posted_at: :desc, id: :desc)
            .offset(page * DiscourseAi::ForumAssistant::Conversations::PAGE_SIZE)
            .limit(DiscourseAi::ForumAssistant::Conversations::PAGE_SIZE + 1)
            .to_a
        has_more = topics.size > DiscourseAi::ForumAssistant::Conversations::PAGE_SIZE
        topics = topics.first(DiscourseAi::ForumAssistant::Conversations::PAGE_SIZE)
        if page.zero?
          starred =
            scope
              .where(id: starred_query)
              .order(last_posted_at: :desc)
              .limit(ConversationStar::MAX_STARS_PER_USER)
              .to_a
          topics = starred + topics
        end
        Topic.preload_custom_fields(topics, ["ai_agent_id"])
        starred_ids =
          ConversationStar.where(user_id: current_user.id, topic_id: topics.map(&:id)).pluck(
            :topic_id,
          )
        render json: {
                 conversations:
                   topics.map do |topic|
                     AiForumAssistantConversationSerializer.new(
                       topic,
                       scope: guardian,
                       root: false,
                       starred_ids: starred_ids,
                     ).as_json
                   end,
                 has_more: has_more,
               }
      end

      def show
        topic = DiscourseAi::ForumAssistant::Conversations.find!(current_user, params[:id])
        posts =
          topic.posts.where(
            post_type: Post.types[:regular],
            user_id: [
              current_user.id,
              DiscourseAi::ForumAssistant::Configuration.bot_user&.id,
            ].compact,
          )
        if params[:before].present?
          before = params[:before].to_i
          raise Discourse::InvalidParameters.new(:before) unless before.positive?
          posts = posts.where("post_number < ?", before)
        end
        posts =
          posts
            .order(post_number: :desc)
            .limit(DiscourseAi::ForumAssistant::Conversations::PAGE_SIZE + 1)
            .to_a
        has_more = posts.size > DiscourseAi::ForumAssistant::Conversations::PAGE_SIZE
        posts = posts.first(DiscourseAi::ForumAssistant::Conversations::PAGE_SIZE).reverse
        starred_ids =
          ConversationStar.where(user_id: current_user.id, topic_id: topic.id).pluck(:topic_id)
        render json: {
                 conversation:
                   AiForumAssistantConversationSerializer.new(
                     topic,
                     scope: guardian,
                     root: false,
                     detail: true,
                     starred_ids: starred_ids,
                   ).as_json,
                 messages: serialize_data(posts, AiForumAssistantMessageSerializer),
                 has_more: has_more,
                 request:
                   DiscourseAi::ForumAssistant::Conversations.request_json(
                     DiscourseAi::ForumAssistant::Conversations.request_for(topic, current_user),
                   ),
               }
      end

      def create
        configuration = DiscourseAi::ForumAssistant::Configuration
        unless configuration.available?
          raise DiscourseAi::ForumAssistant::Policy::Rejected.new(:unavailable)
        end
        create_message(
          title: I18n.t("discourse_ai.ai_bot.default_pm_prefix"),
          archetype: Archetype.private_message,
          target_usernames: configuration.bot_user.username,
          private_message_context: DiscourseAi::AiBot::PERSONAL_MESSAGE_CONTEXT,
          topic_opts: {
            custom_fields: {
              "ai_agent_id" => configuration.agent.id,
            },
          },
        )
      end

      def reply
        topic = DiscourseAi::ForumAssistant::Conversations.find!(current_user, params[:id])
        unless DiscourseAi::ForumAssistant::Policy.authorized_conversation?(topic, current_user)
          raise Discourse::InvalidAccess
        end
        create_message(topic_id: topic.id)
      end

      private

      def create_message(options)
        result =
          NewPostManager.new(
            current_user,
            options.merge(
              raw: params.require(:raw),
              guardian: guardian,
              first_post_checks: true,
              ip_address: request.remote_ip,
              user_agent: request.user_agent,
              referrer: request.env["HTTP_REFERER"],
              writing_device: BrowserDetection.device(request.user_agent),
            ),
          ).perform
        unless result.success? && result.post
          return render_json_error(result.errors.full_messages, status: :unprocessable_entity)
        end
        post = result.post
        render json: {
                 conversation_id: post.topic_id,
                 message: serialize_data(post, AiForumAssistantMessageSerializer, root: false),
                 request:
                   DiscourseAi::ForumAssistant::Conversations.request_json(
                     AiForumAssistantRequest.find_by(post_id: post.id),
                   ),
               }
      end
    end
  end
end
