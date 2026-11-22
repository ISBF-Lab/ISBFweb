# frozen_string_literal: true

require_relative "support"

RSpec.describe DiscourseAi::AiBot::ForumAssistantConversationsController, type: :request do
  include_context "with a configured forum assistant"

  fab!(:admin)

  let(:maintenance) do
    Module.new do
      mattr_accessor :paused, default: false

      def self.paused?(key)
        key == "ai_assistant" && paused
      end
    end
  end

  around { |example| stub_const(Object, :IsbfWorkbenchMaintenance, maintenance) { example.run } }

  describe "#index" do
    it "closes the assistant workspace, history and question APIs without charging a question" do
      question
      accepted_request.finish!("completed")
      sign_in(member)
      maintenance.paused = true

      [
        "/discourse-ai/ai-bot/conversations",
        "/discourse-ai/ai-bot/conversations.json",
        "/discourse-ai/ai-bot/forum-assistant/status.json",
        "/discourse-ai/ai-bot/forum-assistant/conversations.json",
        "/discourse-ai/ai-bot/forum-assistant/conversations/#{conversation.id}.json",
      ].each do |url|
        get url
        expect(response.status).to eq(404)
      end

      [
        "/discourse-ai/ai-bot/forum-assistant/conversations.json",
        "/discourse-ai/ai-bot/forum-assistant/conversations/#{conversation.id}/messages.json",
        "/discourse-ai/ai-bot/conversations.json",
      ].each do |url|
        expect do
          post url,
               params: {
                 raw: "Where can I find the forum resource catalog?",
                 target_username: bot_user.username,
                 ai_agent_id: assistant_agent.id,
               }
        end.not_to change(AiForumAssistantRequest, :count)
        expect(response.status).to eq(404)
      end

      put "/discourse-ai/ai-bot/conversations/#{conversation.id}/starred.json",
          params: {
            starred: true,
          }
      expect(response.status).to eq(404)

      maintenance.paused = false
      get "/discourse-ai/ai-bot/forum-assistant/conversations/#{conversation.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("conversation").fetch("id")).to eq(conversation.id)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
      expect do
        post "/discourse-ai/ai-bot/forum-assistant/conversations.json",
             params: {
               raw: "Where can I find the forum's privacy instructions?",
             }
      end.to change(AiForumAssistantRequest, :count).by(1)
      expect(response.status).to eq(200)
      expect(SiteSetting.ai_forum_assistant_enabled).to eq(true)
      expect(SiteSetting.ai_forum_assistant_restrict_members).to eq(true)
    end

    it "keeps other AI conversations available to administrators during assistant maintenance" do
      assistant_topic = Fabricate(:private_message_topic, user: admin, recipient: bot_user)
      another_topic = Fabricate(:private_message_topic, user: admin, recipient: bot_user)
      [assistant_topic, another_topic].each do |topic|
        topic.custom_fields[DiscourseAi::AiBot::TOPIC_AI_BOT_PM_FIELD] = "t"
      end
      assistant_topic.custom_fields["ai_agent_id"] = assistant_agent.id
      another_topic.custom_fields["ai_agent_id"] = assistant_agent.id + 1
      [assistant_topic, another_topic].each(&:save_custom_fields)
      sign_in(admin)
      maintenance.paused = true

      post "/discourse-ai/ai-bot/conversations.json",
           params: {
             raw: "Find an answer with the forum assistant.",
             target_username: bot_user.username,
             ai_agent_id: assistant_agent.id,
           }
      expect(response.status).to eq(404)

      get "/discourse-ai/ai-bot/conversations"
      expect(response.status).to eq(200)
      get "/discourse-ai/ai-bot/conversations.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("conversations").map { |topic| topic.fetch("id") }).to eq(
        [another_topic.id],
      )
      put "/discourse-ai/ai-bot/conversations/#{another_topic.id}/starred.json",
          params: {
            starred: true,
          }
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("starred")).to eq(true)
    end
  end

  describe "#reply" do
    it "blocks the shared post endpoint for assistant questions and preserves ordinary posts" do
      question
      accepted_request.finish!("completed")
      ordinary_post = Fabricate(:post, user: member)
      sign_in(member)
      maintenance.paused = true

      expect do
        post "/posts.json",
             params: {
               topic_id: conversation.id,
               raw: "Where are this forum's resource instructions?",
             }
      end.not_to change(AiForumAssistantRequest, :count)
      expect(response.status).to eq(404)

      post "/posts.json",
           params: {
             archetype: Archetype.private_message,
             title: "New assistant private conversation",
             raw: "Find the forum's course resource catalog.",
             target_recipients: bot_user.username,
           }
      expect(response.status).to eq(404)

      get "/t/#{ordinary_post.topic_id}.json"
      expect(response.status).to eq(200)
      post "/posts.json",
           params: {
             topic_id: ordinary_post.topic_id,
             raw: "A regular forum reply remains available while the assistant is maintained.",
           }
      expect(response.status).to eq(200)
      expect(Post.find(response.parsed_body.fetch("id")).topic_id).to eq(ordinary_post.topic_id)
    end
  end
end
