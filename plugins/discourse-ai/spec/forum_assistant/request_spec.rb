# frozen_string_literal: true

require_relative "support"

RSpec.describe AiForumAssistantRequest do
  include_context "with a configured forum assistant"

  describe ".admit!" do
    subject(:admission) { described_class.admit!(user: member, post: question) }

    let(:release_initial_request) { true }

    before { accepted_request.finish!("not_found") if release_initial_request }

    it "records one question through PostCreator and reserves both durable daily counters" do
      expect(accepted_request).to have_attributes(user_id: member.id, post_id: question.id)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
      expect(AiForumAssistantQuota.used_by(0)).to eq(1)
      expect(accepted_request.question_digest).to eq(Digest::SHA256.hexdigest(question.raw))
    end

    it "admits question twenty and refuses question twenty-one without increasing counters" do
      AiForumAssistantQuota.for_period(member.id).update!(used: 19)

      allowed = admission
      allowed.finish!("completed")

      expect(AiForumAssistantQuota.used_by(member.id)).to eq(20)
      expect do described_class.admit!(user: member, post: question) end.to raise_error(
        DiscourseAi::ForumAssistant::Policy::Rejected,
      ) { |error| expect(error.reason).to eq("daily_limit") }
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(20)
      expect(AiForumAssistantQuota.used_by(0)).to eq(2)
    end

    it "admits the thousandth site question and refuses the next one atomically" do
      AiForumAssistantQuota.for_period(0).update!(used: 999)
      admission.finish!("completed")

      expect do described_class.admit!(user: member, post: question) end.to raise_error(
        DiscourseAi::ForumAssistant::Policy::Rejected,
      ) { |error| expect(error.reason).to eq("global_limit") }
      expect(AiForumAssistantQuota.used_by(0)).to eq(1000)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(2)
    end

    context "when three attempts have been made within a minute" do
      let(:observe_rate_limits) { true }

      it "refuses the fourth attempt before charging the daily quotas" do
        2.times { described_class.admit!(user: member, post: question).finish!("completed") }

        expect do described_class.admit!(user: member, post: question) end.to raise_error(
          RateLimiter::LimitExceeded,
        )
        expect(AiForumAssistantQuota.used_by(member.id)).to eq(3)
        expect(AiForumAssistantQuota.used_by(0)).to eq(3)
      end
    end

    context "when an account already has an active request" do
      let(:release_initial_request) { false }

      it "rejects a concurrent question without another daily reservation" do
        accepted_request

        expect { admission }.to raise_error(DiscourseAi::ForumAssistant::Policy::Rejected) { |error|
          expect(error.reason).to eq("busy")
        }
        expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
      end
    end

    it "keeps linked accounts' daily quotas and active requests independent" do
      Fabricate(
        :isbf_account_link,
        user_a: member,
        user_b: other_member,
        requester: member,
        status: :approved,
      )
      AiForumAssistantQuota.for_period(member.id).update!(used: 20)
      second_conversation =
        Fabricate(:private_message_topic, user: other_member, recipient: bot_user)
      second_question =
        PostCreator.create!(
          other_member,
          topic_id: second_conversation.id,
          raw: "Please find quartzpilot course resources for my account.",
        )

      expect(described_class.find_by!(post_id: second_question.id).user_id).to eq(other_member.id)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(20)
      expect(AiForumAssistantQuota.used_by(other_member.id)).to eq(1)
    end

    it "starts a fresh quota period at the configured local midnight" do
      freeze_time(Time.utc(2026, 11, 17, 15, 59))
      previous_period = DiscourseAi::ForumAssistant::Configuration.period_start
      AiForumAssistantQuota.for_period(member.id, previous_period).update!(used: 20)
      freeze_time(2.minutes.from_now)

      admission.finish!("completed")

      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
      expect(
        AiForumAssistantQuota.find_by!(user_id: member.id, period_start: previous_period).used,
      ).to eq(20)
      expect(DiscourseAi::ForumAssistant::Configuration.resets_at).to eq_time(
        Time.utc(2026, 11, 18, 16),
      )
    end
  end

  describe "#claim!" do
    it "claims a queued request once so duplicate jobs cannot generate twice" do
      expect(accepted_request.claim!).to eq(true)
      expect(accepted_request.claim!).to eq(false)
      expect(accepted_request.reload.status).to eq("running")
    end

    it "expires an overdue request and restores its personal allowance" do
      accepted_request.update!(expires_at: 1.second.ago)

      expect(accepted_request.claim!).to eq(false)
      expect(accepted_request.reload).to have_attributes(
        status: "expired",
        personal_quota_refunded: true,
      )
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(0)
      expect(AiForumAssistantQuota.used_by(0)).to eq(1)
    end
  end

  describe "#finish!" do
    it "refunds a technical failure once and preserves the global accepted-question count" do
      accepted_request.claim!
      accepted_request.finish!("failed", reason: "unavailable")
      accepted_request.finish!("failed", reason: "unavailable")

      expect(AiForumAssistantQuota.used_by(member.id)).to eq(0)
      expect(AiForumAssistantQuota.used_by(0)).to eq(1)
      expect(DiscourseAi::ForumAssistant::Throttle.active?(member.id)).to eq(false)
    end

    it "keeps a completed answer charged when a stale expiry handler finishes later" do
      accepted_request.claim!
      accepted_request.finish!("completed")
      accepted_request.finish!("expired", reason: "timeout")

      expect(accepted_request.reload).to have_attributes(
        status: "completed",
        personal_quota_refunded: false,
      )
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(1)
    end

    it "releases only its own lock when a newer question is active" do
      accepted_request.finish!("completed")
      newer_request = described_class.admit!(user: member, post: question)
      accepted_request.finish!("expired")

      expect(
        DiscourseAi::ForumAssistant::Throttle.owned?(member.id, newer_request.request_uuid),
      ).to eq(true)
      expect(AiForumAssistantQuota.used_by(member.id)).to eq(2)
    end
  end
end
