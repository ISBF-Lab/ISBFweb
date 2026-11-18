# frozen_string_literal: true

require_relative "support"

RSpec.describe "Forum assistant provider boundary", type: :request do
  include_context "with a configured forum assistant"

  describe "the configured OpenAI-compatible endpoint" do
    it "sends only text and no tools to deepseek-flash with the classification and answer caps" do
      endpoint = "https://api.deepseek.com/chat/completions"
      llm_model.update!(name: "deepseek-flash", url: endpoint, max_prompt_tokens: 100_000)
      SearchIndexer.enable
      source =
        Fabricate(:post, raw: "Quartzpilot resources are described in this forum discussion.")
      answer = "See the [quartzpilot discussion](#{source.relative_url})."
      classification = {
        action: "allow",
        intent: "forum",
        query: "quartzpilot",
        reason: "forum_question",
      }.to_json
      payloads = []
      api_stub =
        stub_request(:post, endpoint).to_return do |http_request|
          payload = JSON.parse(http_request.body)
          payloads << payload
          if payload["stream"]
            chunks = [
              {
                id: "forum-answer",
                object: "chat.completion.chunk",
                model: "deepseek-flash",
                choices: [{ index: 0, delta: { content: answer }, finish_reason: nil }],
              },
              {
                id: "forum-answer",
                object: "chat.completion.chunk",
                model: "deepseek-flash",
                choices: [{ index: 0, delta: {}, finish_reason: "stop" }],
                usage: {
                  prompt_tokens: 40,
                  completion_tokens: 20,
                  total_tokens: 60,
                },
              },
            ]
            body = chunks.map { |chunk| "data: #{chunk.to_json}\n\n" }.join + "data: [DONE]\n\n"
            { status: 200, body: body, headers: { "Content-Type" => "text/event-stream" } }
          else
            body = {
              id: "forum-classification",
              object: "chat.completion",
              model: "deepseek-flash",
              choices: [
                {
                  index: 0,
                  message: {
                    role: "assistant",
                    content: classification,
                  },
                  finish_reason: "stop",
                },
              ],
              usage: {
                prompt_tokens: 25,
                completion_tokens: 15,
                total_tokens: 40,
              },
            }.to_json
            { status: 200, body: body, headers: { "Content-Type" => "application/json" } }
          end
        end

      Jobs::CreateAiForumAssistantReply.new.execute(request_id: accepted_request.id)

      expect(accepted_request.reload.status).to eq("completed")
      expect(accepted_request.reply_post.raw).to eq(answer)
      expect(api_stub).to have_been_requested.twice
      expect(payloads.map { |payload| payload.fetch("model") }).to eq(
        %w[deepseek-flash deepseek-flash],
      )
      expect(payloads.map { |payload| payload.fetch("max_tokens") }).to eq([512, 2000])
      expect(payloads.map { |payload| payload.dig("thinking", "type") }).to eq(
        %w[disabled disabled],
      )
      expect(payloads.first.fetch("response_format")).to eq("type" => "json_object")
      expect(payloads.all? { |payload| payload.fetch("tools", []).empty? }).to eq(true)
      contents =
        payloads.flat_map do |payload|
          payload.fetch("messages").map { |message| message.fetch("content") }
        end
      expect(contents).to all(be_a(String))
      expect(accepted_request.input_tokens).to be > 0
      expect(accepted_request.output_tokens).to be > 0
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
    ensure
      SearchIndexer.disable
    end

    it "cancels during question classification without starting an answer request or publishing a reply" do
      endpoint = "https://api.deepseek.com/chat/completions"
      llm_model.update!(name: "deepseek-flash", url: endpoint, max_prompt_tokens: 100_000)
      accepted_request
      sign_in(member)
      classification = {
        action: "allow",
        intent: "forum",
        query: "quartzpilot",
        reason: "forum_question",
      }.to_json
      api_stub =
        stub_request(:post, endpoint).to_return do
          post "/discourse-ai/ai-bot/forum-assistant/cancel.json"
          expect(response.status).to eq(204)
          body = {
            id: "forum-cancelled-classification",
            object: "chat.completion",
            model: "deepseek-flash",
            choices: [
              {
                index: 0,
                message: {
                  role: "assistant",
                  content: classification,
                },
                finish_reason: "stop",
              },
            ],
            usage: {
              prompt_tokens: 25,
              completion_tokens: 15,
              total_tokens: 40,
            },
          }.to_json
          { status: 200, body: body, headers: { "Content-Type" => "application/json" } }
        end

      Jobs::CreateAiForumAssistantReply.new.execute(request_id: accepted_request.id)

      expect(api_stub).to have_been_requested.once
      expect(accepted_request.reload.status).to eq("cancelled")
      expect(conversation.posts.where(user_id: bot_user.id)).to be_empty
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
      expect(DiscourseAi::ForumAssistant::Throttle.active?(member.id)).to eq(false)
    end
  end
end
