# frozen_string_literal: true

require_relative "support"

RSpec.describe DiscourseAi::ForumAssistant::Answer do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:request_id) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    include_context "with a configured forum assistant"

    let(:params) { { request_id: running_request.id } }
    let(:dependencies) do
      {
        execution_context:
          DiscourseAi::Completions::ExecutionContext.new(
            token_usage_tracker: DiscourseAi::Completions::TokenUsageTracker.new,
          ),
        cancel_manager: DiscourseAi::Completions::CancelManager.new,
      }
    end
    let(:running_request) { accepted_request.tap(&:claim!) }
    let(:classification) do
      { action: "deny", intent: "forum", query: "", reason: "off_topic" }.to_json
    end
    let(:responses) { [classification] }

    around do |example|
      DiscourseAi::Completions::Llm.with_prepared_responses(responses, llm: llm_model) do
        example.run
      end
    end

    context "when the contract is invalid" do
      let(:params) { { request_id: nil } }

      it { is_expected.to fail_a_contract }
    end

    context "when the running request is absent" do
      let(:params) { { request_id: 0 } }

      it { is_expected.to fail_to_find_a_model(:request) }
    end

    context "when the private conversation has another participant" do
      before { running_request.post.topic.allowed_users << other_member }

      it { is_expected.to fail_a_policy(:authorized_conversation) }
    end

    context "when the accepted question was edited before execution" do
      before do
        running_request.post.update_columns(
          raw: "An edited question after the original reservation",
        )
      end

      it { is_expected.to fail_a_policy(:authorized_conversation) }
    end

    context "when question classification is malformed" do
      let(:classification) { "not valid JSON" }

      it { is_expected.to fail_to_find_a_model(:decision) }
    end

    context "when the active request was cancelled during question checking" do
      before do
        running_request
        DiscourseAi::ForumAssistant::Throttle.release(member.id, running_request.request_uuid)
      end

      it { is_expected.to fail_a_policy(:request_active) }
    end

    context "when the question is outside the forum scope" do
      it "publishes the fixed refusal and retains one charged question" do
        expect(result).to run_successfully
        expect(running_request.reload).to have_attributes(status: "refused", reason: "off_topic")
        expect(running_request.reply_post.raw).to eq(
          I18n.t("discourse_ai.forum_assistant.replies.refused"),
        )
        expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
        expect(DiscourseAi::Completions::Llm.prompts.length).to eq(1)
      end
    end

    context "when the question is ambiguous" do
      let(:classification) do
        { action: "clarify", intent: "resources", query: "", reason: "ambiguous" }.to_json
      end

      it "asks for clarification without recording a policy violation" do
        SiteSetting.ai_forum_assistant_violation_limit = 1

        expect(result).to run_successfully
        expect(running_request.reload.status).to eq("clarified")
        expect(running_request.reply_post.raw).to eq(
          I18n.t("discourse_ai.forum_assistant.replies.clarify"),
        )
        expect(DiscourseAi::ForumAssistant::Throttle.blocked_until(member.id)).to eq(nil)
      end
    end

    context "when no authorized source matches" do
      let(:classification) do
        {
          action: "allow",
          intent: "forum",
          query: "quartzpilotmissing",
          reason: "forum_question",
        }.to_json
      end

      it "returns a forum-search suggestion without a general-purpose answer call" do
        expect(result).to run_successfully
        expect(running_request.reload.status).to eq("not_found")
        expect(running_request.reply_post.raw).to eq(
          I18n.t("discourse_ai.forum_assistant.replies.not_found"),
        )
        expect(DiscourseAi::Completions::Llm.prompts.length).to eq(1)
      end
    end

    context "when the question has a visible forum source" do
      let(:classification) do
        { action: "allow", intent: "forum", query: "quartzpilot", reason: "forum_question" }.to_json
      end
      let(:responses) { [classification, answer_text] }
      let(:answer_text) { "See [the quartzpilot discussion](#{source_post.relative_url})." }
      let(:source_post) do
        Fabricate(:post, raw: "A quartzpilot resource is available in the forum handbook.")
      end
      let(:messages) do
        MessageBus.track_publish("discourse-ai/ai-bot/topic/#{question.topic_id}") { result }
      end

      before do
        SearchIndexer.enable
        SearchIndexer.index(source_post, force: true)
      end

      after { SearchIndexer.disable }

      it "streams a grounded answer with no native or function tools and a bounded output" do
        published_messages = messages
        expect(result).to run_successfully
        expect(running_request.reload.status).to eq("completed")
        expect(published_messages).to be_present
        expect(running_request.reply_post.raw).to eq(answer_text)
        expect(running_request.source_refs).to include("kind" => "post", "id" => source_post.id)
        prompt = DiscourseAi::Completions::Llm.prompts.last
        expect(prompt.tools).to eq([])
        expect(prompt.native_tools).to eq([])
        expect(DiscourseAi::Completions::Llm.prompt_options.last[:max_tokens]).to eq(2000)
        expect(prompt.messages.to_json).to include(source_post.relative_url)
      end
    end
  end
end
