# frozen_string_literal: true

require_relative "support"

RSpec.describe DiscourseAi::AiBot::ForumAssistantConversationsController, type: :request do
  include_context "with a configured forum assistant"

  let(:base) { "/discourse-ai/ai-bot/forum-assistant/conversations" }

  before { sign_in(member) }

  it "lists only the owner's forum conversations with question titles and stars" do
    question
    human_message = Fabricate(:private_message_topic, user: member, recipient: other_member)
    foreign_message = Fabricate(:private_message_topic, user: other_member, recipient: bot_user)
    other_agent_message = Fabricate(:private_message_topic, user: member, recipient: bot_user)
    other_agent_message.custom_fields["ai_agent_id"] = assistant_agent.id + 1
    other_agent_message.save_custom_fields
    DiscourseAi::AiBot::ConversationStar.create!(user: member, topic: conversation)

    get "#{base}.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body.fetch("conversations")).to contain_exactly(
      include("id" => conversation.id, "title" => question.raw, "starred" => true),
    )
    expect(response.parsed_body.fetch("has_more")).to eq(false)
    expect(response.body).not_to include(
      human_message.title,
      foreign_message.title,
      other_agent_message.title,
    )
  end

  it "returns messages and the current request without exposing audit metadata" do
    question
    reply = Fabricate(:post, topic: conversation, user: bot_user, raw: "A forum answer.")
    accepted_request.update!(reply_post: reply)
    accepted_request.finish!("completed")

    get "#{base}/#{conversation.id}.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body.fetch("messages")).to contain_exactly(
      include("id" => question.id, "role" => "user", "raw" => question.raw),
      include("id" => reply.id, "role" => "assistant", "cooked" => reply.cooked),
    )
    expect(response.parsed_body.fetch("conversation")).to include("read_only" => false)
    expect(response.parsed_body.fetch("request").keys).to contain_exactly(
      "id",
      "post_id",
      "reply_post_id",
      "status",
      "expires_at",
    )
  end

  it "keeps an older starred conversation on the first page" do
    question
    conversation.update_columns(last_posted_at: 1.year.ago)
    DiscourseAi::AiBot::ConversationStar.create!(user: member, topic: conversation)
    stub_const(DiscourseAi::ForumAssistant::Conversations, :PAGE_SIZE, 1) do
      recent = Fabricate(:private_message_topic, user: member, recipient: bot_user)
      get "#{base}.json"

      expect(response.parsed_body.fetch("conversations").map { |item| item["id"] }).to eq(
        [conversation.id, recent.id],
      )
    end
  end

  it "rejects invalid and unbounded page offsets" do
    %w[-1 invalid 99999999999999999999].each do |page|
      get "#{base}.json", params: { page: page }
      expect(response.status).to eq(400)
    end
  end

  it "paginates earlier messages without losing their order" do
    question
    replies = Fabricate.times(42, :post, topic: conversation, user: bot_user)

    get "#{base}/#{conversation.id}.json"
    latest = response.parsed_body
    expect(latest.fetch("messages").map { |message| message["id"] }).to eq(
      replies.last(40).map(&:id),
    )
    expect(latest.fetch("has_more")).to eq(true)

    get "#{base}/#{conversation.id}.json",
        params: {
          before: latest["messages"].first["post_number"],
        }

    expect(response.parsed_body.fetch("messages").map { |message| message["id"] }).to eq(
      [question.id, *replies.first(2).map(&:id)],
    )
    expect(response.parsed_body.fetch("has_more")).to eq(false)
  end

  it "keeps a changed conversation readable while denying further questions" do
    question
    conversation.allowed_users << other_member

    get "#{base}/#{conversation.id}.json"
    expect(response.parsed_body.fetch("conversation")).to include("read_only" => true)

    expect do
      post "#{base}/#{conversation.id}/messages.json", params: { raw: "Find forum rules." }
    end.not_to change(AiForumAssistantRequest, :count)
    expect(response.status).to eq(403)
  end

  it "creates a server-selected assistant conversation and reserves one question" do
    post "#{base}.json",
         params: {
           raw: "Where do I find forum privacy settings?",
           target_username: other_member.username,
           target_usernames: other_member.username,
           ai_agent_id: assistant_agent.id + 1,
           topic_id: -1,
         }

    expect(response.status).to eq(200)
    created = Topic.find(response.parsed_body.fetch("conversation_id"))
    expect(created.user_id).to eq(member.id)
    expect(created.allowed_users.pluck(:id)).to contain_exactly(member.id, bot_user.id)
    expect(created.custom_fields["ai_agent_id"].to_i).to eq(assistant_agent.id)
    expect(response.parsed_body.fetch("message")).to include("role" => "user")
    expect(response.parsed_body.fetch("request")).to include("status" => "queued")
    expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
  end

  it "appends a follow-up to the same conversation with a fresh reservation" do
    accepted_request.finish!("completed")

    post "#{base}/#{conversation.id}/messages.json",
         params: {
           raw: "Which forum topic explains those resources?",
         }

    expect(response.status).to eq(200)
    expect(response.parsed_body.fetch("conversation_id")).to eq(conversation.id)
    expect(response.parsed_body.fetch("message")).to include("post_number" => 2)
    expect(AiForumAssistantQuota.used_by(member.id)).to eq(2)
  end

  it "rejects attachments and overlong questions without charging quota" do
    ["Read upload://example.pdf", "a" * 4001].each do |raw|
      post "#{base}.json", params: { raw: raw }

      expect(response.status).to eq(422)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(0)
    end
  end

  it "preserves the per-user concurrency limit" do
    accepted_request

    expect do
      post "#{base}.json", params: { raw: "Where are the forum announcements?" }
    end.not_to change(AiForumAssistantRequest, :count)

    expect(response.status).to eq(422)
    expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
  end

  it "preserves daily limits and disabled configuration" do
    AiForumAssistantQuota.for_period(member.id).update!(used: 20)
    post "#{base}.json", params: { raw: "Where are the forum announcements?" }
    expect(response.status).to eq(422)
    expect(AiForumAssistantQuota.used_by(member.id)).to eq(20)

    SiteSetting.ai_forum_assistant_enabled = false
    post "#{base}.json", params: { raw: "Where are the forum announcements?" }
    expect(response.status).to eq(503)
  end

  it "returns the same not-found response for inaccessible conversations" do
    question
    sign_in(other_member)

    get "#{base}/#{conversation.id}.json"
    expect(response.status).to eq(404)
    post "#{base}/#{conversation.id}/messages.json",
         params: {
           raw: "Read another account's answer.",
         }
    expect(response.status).to eq(404)
    get "#{base}/0.json"
    expect(response.status).to eq(404)
  end

  it "requires login for listing, reading and writing" do
    question
    reset!

    get "#{base}.json"
    expect(response.status).to eq(403)
    get "#{base}/#{conversation.id}.json"
    expect(response.status).to eq(403)
    post "#{base}.json", params: { raw: question.raw }
    expect(response.status).to eq(403)
  end

  it "cancels only the selected owned conversation" do
    accepted_request
    other = Fabricate(:private_message_topic, user: member, recipient: bot_user)

    post "/discourse-ai/ai-bot/forum-assistant/cancel.json", params: { conversation_id: other.id }
    expect(response.status).to eq(204)
    expect(accepted_request.reload.status).to eq("queued")

    post "/discourse-ai/ai-bot/forum-assistant/cancel.json",
         params: {
           conversation_id: conversation.id,
         }
    expect(response.status).to eq(204)
    expect(accepted_request.reload.status).to eq("cancelled")
  end
end
