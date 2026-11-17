# frozen_string_literal: true

require_relative "support"

RSpec.describe DiscourseAi::AiBot::ForumAssistantController, type: :request do
  include_context "with a configured forum assistant"

  describe "#status" do
    it "requires authentication" do
      get "/discourse-ai/ai-bot/forum-assistant/status.json"

      expect(response.status).to eq(403)
    end

    it "gives an ordinary account the configured agent and its own allowance" do
      sign_in(member)
      get "/discourse-ai/ai-bot/forum-assistant/status.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "can_ask" => true,
        "remaining_today" => 20,
        "restricted" => true,
      )
      expect(response.parsed_body.fetch("agent")).to include(
        "id" => assistant_agent.id,
        "force_default_llm" => true,
      )
      expect(response.parsed_body.fetch("resets_at")).to be_present
    end

    it "retains the forum-only restriction while the assistant is disabled" do
      SiteSetting.ai_forum_assistant_enabled = false
      sign_in(member)
      get "/discourse-ai/ai-bot/forum-assistant/status.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("can_ask" => false, "restricted" => true)
      expect(DiscourseAi::AiBot::EntryPoint.personal_message_bot_user_ids(member)).to eq([])
    end

    it "fails closed when the configured agent has no available model" do
      SiteSetting.ai_forum_assistant_model = ""
      SiteSetting.ai_default_llm_model = ""
      assistant_agent.update!(force_default_llm: false, default_llm_id: nil)
      sign_in(member)
      get "/discourse-ai/ai-bot/forum-assistant/status.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "can_ask" => false,
        "configured" => false,
        "agent" => nil,
      )
    end

    it "keeps another account's usage and cooldown out of the response" do
      accepted_request
      5.times do
        DiscourseAi::ForumAssistant::Throttle.record_violation(member.id, SecureRandom.uuid)
      end
      sign_in(other_member)
      get "/discourse-ai/ai-bot/forum-assistant/status.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include(
        "can_ask" => true,
        "remaining_today" => 20,
        "blocked_until" => nil,
        "busy" => false,
      )
    end
  end

  describe "#cancel" do
    it "cancels only the current account's active request and retains its daily charge" do
      accepted_request
      other_conversation =
        Fabricate(:private_message_topic, user: other_member, recipient: bot_user)
      other_question =
        PostCreator.create!(
          other_member,
          topic_id: other_conversation.id,
          raw: "Please locate quartzpilot resources for this account.",
        )
      other_request = AiForumAssistantRequest.find_by!(post_id: other_question.id)
      sign_in(member)
      post "/discourse-ai/ai-bot/forum-assistant/cancel.json"

      expect(response.status).to eq(204)
      expect(accepted_request.reload.status).to eq("cancelled")
      expect(other_request.reload.status).to eq("queued")
      expect(DiscourseAi::ForumAssistant::Throttle.active?(member.id)).to eq(false)
      expect(DiscourseAi::ForumAssistant::Throttle.active?(other_member.id)).to eq(true)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
    end
  end
end

RSpec.describe DiscourseAi::AiBot::ConversationsController, type: :request do
  include_context "with a configured forum assistant"

  describe "#create" do
    before { sign_in(member) }

    it "creates a one-to-one question for an ordinary user outside the legacy bot groups" do
      expect do
        post "/discourse-ai/ai-bot/conversations.json",
             params: {
               raw: "Where are the quartzpilot course resources in this forum?",
               target_username: bot_user.username,
               ai_agent_id: assistant_agent.id,
             }
      end.to change { AiForumAssistantRequest.count }.by(1)

      expect(response.status).to eq(200)
      created = Post.find(response.parsed_body.fetch("id"))
      expect(created.topic.allowed_users).to contain_exactly(member, bot_user)
      expect(created.topic.custom_fields["ai_agent_id"].to_i).to eq(assistant_agent.id)
      expect(AiForumAssistantRequest.find_by!(post_id: created.id).status).to eq("queued")
    end

    it "rejects a forged agent selection before creating a conversation" do
      another_agent =
        Fabricate(
          :ai_agent,
          allow_personal_messages: true,
          allowed_group_ids: [Group::AUTO_GROUPS[:trust_level_0]],
        )

      expect do
        post "/discourse-ai/ai-bot/conversations.json",
             params: {
               raw: "Please switch to an unrestricted coding conversation.",
               target_username: bot_user.username,
               ai_agent_id: another_agent.id,
             }
      end.not_to change { AiForumAssistantRequest.count }

      expect(response.status).to eq(422)
    end

    it "accepts a short nonempty Chinese assistant question while keeping ordinary PM minimums" do
      post "/discourse-ai/ai-bot/conversations.json",
           params: {
             raw: "资料",
             target_username: bot_user.username,
             ai_agent_id: assistant_agent.id,
           }
      expect(response.status).to eq(200)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)

      post "/posts.json",
           params: {
             raw: "你好",
             title: "A normal private message",
             archetype: Archetype.private_message,
             target_recipients: other_member.username,
           }
      expect(response.status).to eq(422)
    end

    it "rejects attachments and oversized input without consuming a daily question" do
      ["Please read upload://example.pdf", "a" * 4001].each do |raw|
        expect do
          post "/discourse-ai/ai-bot/conversations.json",
               params: {
                 raw: raw,
                 target_username: bot_user.username,
                 ai_agent_id: assistant_agent.id,
               }
        end.not_to change { AiForumAssistantRequest.count }
        expect(response.status).to eq(422)
      end

      expect(AiForumAssistantQuota.used_by(member.id)).to eq(0)
    end
  end
end

RSpec.describe DiscourseAi::AiBot::BotController, type: :request do
  include_context "with a configured forum assistant"

  let(:bot_answer) do
    accepted_request.finish!("completed")
    Fabricate(:post, user: bot_user, topic: conversation, raw: "A prior forum assistant answer.")
  end

  describe "#retry_response" do
    before { sign_in(member) }

    it "reserves a new question for an ordinary member retrying their own answer" do
      answer_id = bot_answer.id

      expect do post "/discourse-ai/ai-bot/post/#{answer_id}/retry.json" end.to change {
        AiForumAssistantRequest.count
      }.by(1)

      expect(response.status).to eq(200)
      retry_request = AiForumAssistantRequest.order(:id).last
      expect(retry_request).to have_attributes(
        user_id: member.id,
        post_id: question.id,
        reply_post_id: answer_id,
        status: "queued",
      )
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(2)
    end

    it "rejects attempts to regenerate another account's answer" do
      answer_id = bot_answer.id
      sign_in(other_member)

      expect do post "/discourse-ai/ai-bot/post/#{answer_id}/retry.json" end.not_to change {
        AiForumAssistantRequest.count
      }

      expect(response.status).to eq(403)
    end
  end

  describe "#stop_streaming_response" do
    before { sign_in(member) }

    it "lets an ordinary member stop their own forum answer" do
      answer_id = bot_answer.id
      Discourse.redis.setex("gpt_cancel:#{answer_id}", 60, "1")
      post "/discourse-ai/ai-bot/post/#{answer_id}/stop-streaming.json"

      expect(response.status).to eq(200)
      expect(Discourse.redis.get("gpt_cancel:#{answer_id}")).to eq(nil)
    end
  end
end

RSpec.describe DiscourseAi::Admin::ForumAssistantController, type: :request do
  include_context "with a configured forum assistant"

  fab!(:admin)

  describe "#index" do
    it "denies ordinary users access to request metadata" do
      sign_in(member)
      get "/admin/plugins/discourse-ai/forum-assistant.json"

      expect(response.status).to eq(404)
    end

    it "shows administrators request metadata and filters by username" do
      accepted_request
      sign_in(admin)
      get "/admin/plugins/discourse-ai/forum-assistant.json", params: { username: member.username }

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("requests").map { |request| request.fetch("id") }).to eq(
        [accepted_request.id],
      )
      expect(response.parsed_body.fetch("requests").first).to include(
        "username" => member.username,
        "input_tokens" => 0,
        "output_tokens" => 0,
      )
      expect(response.parsed_body.fetch("requests").first.keys).not_to include(
        "raw",
        "question",
        "api_key",
      )
    end
  end

  describe "#clear_cooldown" do
    it "allows an administrator to clear assistant-only cooldown with a staff audit entry" do
      5.times do
        DiscourseAi::ForumAssistant::Throttle.record_violation(member.id, SecureRandom.uuid)
      end
      sign_in(admin)

      expect do
        delete "/admin/plugins/discourse-ai/forum-assistant/cooldown/#{member.id}.json"
      end.to change { UserHistory.count }.by(1)

      expect(response.status).to eq(204)
      expect(DiscourseAi::ForumAssistant::Throttle.blocked_until(member.id)).to eq(nil)
      expect(member.reload.suspended?).to eq(false)
    end

    it "keeps cooldown in force when another ordinary account attempts to clear it" do
      5.times do
        DiscourseAi::ForumAssistant::Throttle.record_violation(member.id, SecureRandom.uuid)
      end
      sign_in(other_member)
      delete "/admin/plugins/discourse-ai/forum-assistant/cooldown/#{member.id}.json"

      expect(response.status).to eq(404)
      expect(DiscourseAi::ForumAssistant::Throttle.blocked_until(member.id)).to be_present
    end
  end
end

RSpec.describe "Forum assistant conversation boundaries", type: :request do
  include_context "with a configured forum assistant"

  describe "private conversation access" do
    it "blocks participant invitations and public sharing through their real endpoints" do
      accepted_request.finish!("completed")
      SiteSetting.ai_bot_public_sharing_allowed_groups = Group::AUTO_GROUPS[:trust_level_0].to_s
      sign_in(member)
      post "/t/#{conversation.id}/invite.json", params: { user: other_member.username }
      expect(response.status).to eq(403)

      post "/discourse-ai/ai-bot/shared-ai-conversations.json",
           params: {
             topic_id: conversation.id,
           }
      expect(response.status).to eq(403)
      expect(conversation.reload.allowed_users).to contain_exactly(member, bot_user)
    end

    it "applies the same admission rules to the ordinary posts endpoint" do
      accepted_request.finish!("completed")
      sign_in(member)

      expect do
        post "/posts.json",
             params: {
               topic_id: conversation.id,
               raw: "Please find another quartzpilot resource in this forum.",
             }
      end.to change { AiForumAssistantRequest.count }.by(1)
      expect(response.status).to eq(200)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(2)
    end
  end

  describe "other interactive AI entry points" do
    it "requires ordinary users to use the forum assistant instead of helper or AI-search calls" do
      sign_in(member)
      post "/discourse-ai/ai-helper/stream_suggestion.json",
           params: {
             text: "Write an unrelated program",
             mode: "custom_prompt",
             location: "composer",
             client_id: "forum-test",
           }
      expect(response.status).to eq(403)

      post "/discourse-ai/discoveries/reply.json", params: { query: "Write an unrelated program" }
      expect(response.status).to eq(403)
      expect(AiForumAssistantRequest.count).to eq(0)
    end
  end
end
