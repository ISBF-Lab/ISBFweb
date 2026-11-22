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

    it "supports a resource overview without a keyword" do
      classification = {
        action: "allow",
        intent: "resource_overview",
        query: "",
        reason: "forum_question",
        resource_scope: "courses",
      }.to_json

      DiscourseAi::Completions::Llm.with_prepared_responses([classification], llm: llm_model) do
        expect(decision).to have_attributes(
          action: "allow",
          intent: "resource_overview",
          query: "",
          resource_scope: "courses",
        )
      end
    end

    context "when a known course name follows a request to browse resources" do
      fab!(:admin)
      fab!(:course_category, :category)

      let(:question_raw) { "微观经济学" }
      let(:overview_question) { "所有课程资料" }

      before do
        SiteSetting.isbf_learning_enabled = true
        SiteSetting.isbf_learning_category_id = course_category.id
        course_category.set_permissions(trust_level_0: :full, staff: :full)
        course_category.save!
        IsbfLearning::Courses.create(admin, name: question_raw, grade: 1)

        previous = PostCreator.create!(member, topic_id: conversation.id, raw: overview_question)
        AiForumAssistantRequest.find_by!(post_id: previous.id).finish!("completed")
      end

      it "routes the new subject to resource search when the model repeats the overview intent" do
        classification = {
          action: "allow",
          intent: "resource_overview",
          query: "",
          reason: "forum_question",
          resource_scope: "courses",
        }.to_json

        DiscourseAi::Completions::Llm.with_prepared_responses([classification], llm: llm_model) do
          expect(decision).to have_attributes(
            action: "allow",
            intent: "resources",
            query: question_raw,
          )
          prompt = DiscourseAi::Completions::Llm.prompts.first
          input = JSON.parse(prompt.messages.last[:content])
          expect(input.fetch("previous_questions")).to eq([overview_question])
        end
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
        valid.merge(alternatives: %w[second third fourth]).to_json,
        valid.merge(alternatives: ["x" * 201]).to_json,
        valid.merge(alternatives: [123]).to_json,
        valid.merge(resource_scope: "external").to_json,
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
