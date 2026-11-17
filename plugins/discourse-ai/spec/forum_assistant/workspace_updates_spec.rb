# frozen_string_literal: true

require_relative "support"

RSpec.describe AiForumAssistantRequest do
  include_context "with a configured forum assistant"

  it "publishes a terminal state only to its owner after refunding a failed request" do
    accepted_request
    channel = "/discourse-ai/forum-assistant/user/#{member.id}"

    messages = MessageBus.track_publish(channel) { accepted_request.finish!("failed") }

    expect(messages).not_to be_empty
    expect(messages.last.data).to include(conversation_id: conversation.id)
    expect(messages.last.data.fetch(:request)).to include(status: "failed")
    expect(messages.last.user_ids).to eq([member.id])
    expect(AiForumAssistantQuota.used_by(member.id)).to eq(0)
  end

  it "reports expired pending requests without leaving the interface generating forever" do
    accepted_request.update!(expires_at: 1.second.ago)

    result = DiscourseAi::ForumAssistant::Conversations.request_json(accepted_request)

    expect(result).to include(status: "expired")
  end
end
