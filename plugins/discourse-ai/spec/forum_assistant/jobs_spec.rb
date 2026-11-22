# frozen_string_literal: true

require_relative "support"

RSpec.describe Jobs::CreateAiForumAssistantReply do
  include_context "with a configured forum assistant"

  describe "#execute" do
    subject(:execution) { described_class.new.execute(request_id: accepted_request.id) }

    it "deduplicates completed jobs without generating or charging twice" do
      refusal = { action: "deny", intent: "forum", query: "", reason: "off_topic" }.to_json
      DiscourseAi::Completions::Llm.with_prepared_responses([refusal], llm: llm_model) do |gateway|
        execution
        described_class.new.execute(request_id: accepted_request.id)

        expect(gateway.completions).to eq(1)
      end

      expect(accepted_request.reload.status).to eq("refused")
      expect(accepted_request.post.topic.posts.where(user_id: bot_user.id).count).to eq(1)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
    end

    it "fails closed on malformed classification and refunds only the personal daily charge" do
      DiscourseAi::Completions::Llm.with_prepared_responses(["unparseable"], llm: llm_model) do
        execution
      end

      expect(accepted_request.reload).to have_attributes(
        status: "failed",
        reason: "unavailable",
        personal_quota_refunded: true,
      )
      expect(accepted_request.reply_post.raw).to eq(
        I18n.t("discourse_ai.forum_assistant.replies.unavailable"),
      )
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(0)
      expect(AiForumAssistantQuota.used_by(0)).to eq(1)
      expect(DiscourseAi::ForumAssistant::Throttle.blocked_until(member.id)).to eq(nil)
      expect(DiscourseAi::ForumAssistant::Throttle.active?(member.id)).to eq(false)
    end

    it "restores personal allowance after a model timeout without a policy violation" do
      DiscourseAi::Completions::Llm.with_prepared_responses(
        [Timeout::Error.new("private provider detail")],
        llm: llm_model,
      ) { execution }

      expect(accepted_request.reload).to have_attributes(
        status: "failed",
        personal_quota_refunded: true,
      )
      expect(accepted_request.reply_post.raw).not_to include("private provider detail")
      expect(DiscourseAi::ForumAssistant::Throttle.blocked_until(member.id)).to eq(nil)
    end

    it "blocks a fabricated tool call even if the answer model emits one" do
      SearchIndexer.enable
      source = Fabricate(:post, raw: "Visible quartzpilot documentation.")
      allowed = {
        action: "allow",
        intent: "forum",
        query: "quartzpilot",
        reason: "forum_question",
      }.to_json
      forbidden_tool =
        DiscourseAi::Completions::ToolCall.new(
          id: "malicious-tool",
          name: "google",
          parameters: {
            query: "leave the forum",
          },
        )

      DiscourseAi::Completions::Llm.with_prepared_responses(
        [allowed, forbidden_tool],
        llm: llm_model,
      ) { execution }

      expect(accepted_request.reload.status).to eq("failed")
      expect(accepted_request.source_refs).to include("kind" => "post", "id" => source.id)
      expect(accepted_request.reply_post.raw).to eq(
        I18n.t("discourse_ai.forum_assistant.replies.unavailable"),
      )
    ensure
      SearchIndexer.disable
    end

    context "when the latest question is Chinese" do
      let(:question_raw) { "微观经济学有哪些资料？" }

      it "publishes Chinese citations when the model emits an English answer" do
        SiteSetting.search_tokenize_chinese = true
        SearchIndexer.enable
        topic = Fabricate(:topic, title: "微观经济学课程和复习资料浏览指南")
        source = Fabricate(:post, topic: topic, raw: "微观经济学 课程讨论。")
        classification = {
          action: "allow",
          intent: "forum",
          query: "微观经济学",
          reason: "forum_question",
          language: "zh-CN",
        }.to_json
        english_prose = "The forum has a discussion on this subject."
        english_answer = "#{english_prose}\n\n[#{topic.title}](#{source.relative_url})"

        updates =
          DiscourseAi::Completions::Llm.with_prepared_responses(
            [classification, english_answer],
            llm: llm_model,
          ) do |gateway|
            messages =
              MessageBus.track_publish("discourse-ai/ai-bot/topic/#{conversation.id}") { execution }
            expect(gateway.completions).to eq(2)
            messages
          end

        expect(accepted_request.reload.status).to eq("completed")
        expect(accepted_request.reply_post.raw).to include(source.relative_url)
        expect(accepted_request.reply_post.raw).to match(/\p{Han}/)
        expect(accepted_request.reply_post.raw).not_to include(english_prose)
        expect(updates).to be_present
        expect(updates.map(&:data).to_json).not_to include(english_prose)
      ensure
        SearchIndexer.disable
      end
    end

    it "uses English for an English question after a Chinese question in the same conversation" do
      previous = PostCreator.create!(member, topic_id: conversation.id, raw: "请问论坛有什么复习资料？")
      AiForumAssistantRequest.find_by!(post_id: previous.id).finish!("completed")
      SearchIndexer.enable
      source = Fabricate(:post, raw: "Quartzpilot revision notes are available in this discussion.")
      classification = {
        action: "allow",
        intent: "forum",
        query: "quartzpilot",
        reason: "forum_question",
        language: "en",
      }.to_json
      english_answer = "See the [discussion](#{source.relative_url}) for the revision notes."

      DiscourseAi::Completions::Llm.with_prepared_responses(
        [classification, english_answer],
        llm: llm_model,
      ) { execution }

      expect(accepted_request.reload.status).to eq("completed")
      expect(accepted_request.reply_post.raw).to eq(english_answer)
    ensure
      SearchIndexer.disable
    end

    it "refuses execution when the question's author loses access before the job runs" do
      accepted_request
      conversation.topic_allowed_users.where(user_id: member.id).delete_all

      DiscourseAi::Completions::Llm.with_prepared_responses([], llm: llm_model) { execution }

      expect(accepted_request.reload).to have_attributes(
        status: "failed",
        personal_quota_refunded: true,
      )
      expect(conversation.posts.where(user_id: bot_user.id)).to be_empty
    end
  end
end

RSpec.describe DiscourseAi::ForumAssistant::Throttle do
  include_context "with a configured forum assistant"

  describe ".record_violation" do
    it "starts a thirty-minute assistant-only cooldown on the fifth recent violation" do
      freeze_time
      4.times { described_class.record_violation(member.id, SecureRandom.uuid) }
      expect(described_class.blocked_until(member.id)).to eq(nil)

      described_class.record_violation(member.id, SecureRandom.uuid)

      expect(described_class.blocked_until(member.id)).to be_within(1.second).of(
        30.minutes.from_now,
      )
      expect(member.reload.suspended?).to eq(false)
      expect(described_class.blocked_until(other_member.id)).to eq(nil)
    end

    it "excludes violations outside the rolling ten-minute window" do
      freeze_time
      4.times { described_class.record_violation(member.id, SecureRandom.uuid) }
      freeze_time(11.minutes.from_now)
      described_class.record_violation(member.id, SecureRandom.uuid)

      expect(described_class.blocked_until(member.id)).to eq(nil)
    end
  end
end

RSpec.describe Jobs::CleanUpAiForumAssistantRequests do
  include_context "with a configured forum assistant"

  describe "#execute" do
    it "expires an orphaned active question and refunds its personal allowance" do
      accepted_request.update!(expires_at: 1.minute.ago)
      described_class.new.execute({})

      expect(accepted_request.reload).to have_attributes(
        status: "expired",
        personal_quota_refunded: true,
      )
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(0)
      expect(AiForumAssistantQuota.used_by(0)).to eq(1)
    end

    it "purges expired metadata while preserving current questions and forum conversations" do
      accepted_request.finish!("completed")
      accepted_request.update_columns(created_at: 31.days.ago)
      described_class.new.execute({})

      expect(AiForumAssistantRequest.exists?(accepted_request.id)).to eq(false)
      expect(Post.exists?(question.id)).to eq(true)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
    end
  end
end
