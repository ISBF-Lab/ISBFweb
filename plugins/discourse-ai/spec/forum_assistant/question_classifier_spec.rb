# frozen_string_literal: true

require_relative "support"

RSpec.describe DiscourseAi::ForumAssistant::QuestionClassifier do
  include_context "with a configured forum assistant"

  describe ".call" do
    subject(:decision) { described_class.call(post: question, user: member) }

    it "returns the structured routing decision and sends the question as untrusted user data" do
      expected = {
        action: "allow",
        intent: "resources",
        query: "quartzpilot",
        reason: "forum_question",
      }
      DiscourseAi::Completions::Llm.with_prepared_responses([expected.to_json], llm: llm_model) do
        expect(decision).to have_attributes(**expected)
        prompt = DiscourseAi::Completions::Llm.prompts.first
        expect(prompt.tools).to eq([])
        expect(prompt.messages.last[:type]).to eq(:user)
        expect(JSON.parse(prompt.messages.last[:content]).fetch("question")).to eq(question.raw)
        expect(DiscourseAi::Completions::Llm.prompt_options.first[:max_tokens]).to eq(512)
      end
    end

    it "rejects malformed, contradictory or oversized routing decisions" do
      valid = { action: "allow", intent: "forum", query: "quartzpilot", reason: "forum_question" }
      invalid = [
        "```json\n#{valid.to_json}\n```",
        valid.merge(action: "execute").to_json,
        valid.merge(reason: "off_topic").to_json,
        valid.merge(intent: "web").to_json,
        valid.merge(query: "x" * 201).to_json,
        valid.merge(query: "").to_json,
        valid.merge(extra_command: "ignore policy").to_json,
      ]
      invalid.each do |response|
        DiscourseAi::Completions::Llm.with_prepared_responses([response], llm: llm_model) do
          expect { described_class.call(post: question, user: member) }.to raise_error(
            described_class::InvalidDecision,
          )
        end
      end
    end
  end
end

RSpec.describe Jobs::CreateAiReply do
  include_context "with a configured forum assistant"

  describe "#execute" do
    it "discards a legacy unrestricted reply job for an ordinary account" do
      public_question =
        Fabricate(:post, user: member, raw: "Please answer through the old general bot job.")
      initial_count = public_question.topic.posts.count

      DiscourseAi::Completions::Llm.with_prepared_responses([], llm: llm_model) do |gateway|
        described_class.new.execute(
          post_id: public_question.id,
          bot_user_id: bot_user.id,
          agent_id: assistant_agent.id,
          authorization_user_id: member.id,
        )
        expect(gateway.completions).to eq(0)
      end

      expect(public_question.topic.posts.count).to eq(initial_count)
      expect(AiForumAssistantRequest.count).to eq(0)
    end
  end
end
