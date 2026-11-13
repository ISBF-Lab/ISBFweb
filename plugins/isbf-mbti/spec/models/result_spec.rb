# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe IsbfMbti::Result do
  fab!(:user)
  let(:answers) { (1..40).map { |question_id| { id: question_id, choice: 1 } } }
  let(:attempt_id) { SecureRandom.uuid }

  describe ".record!" do
    it "stores only the scored result and preserves the same record on a retry" do
      result =
        described_class.record!(
          user: user,
          variant: "40",
          version: "isbf-2",
          attempt_id: attempt_id,
          answers: answers,
        )
      retry_result =
        described_class.record!(
          user: user,
          variant: "40",
          version: "isbf-2",
          attempt_id: attempt_id.upcase,
          answers: answers.reverse,
        )
      expect(retry_result.id).to eq(result.id)
      expect(described_class.where(user_id: user.id).count).to eq(1)
      expect(result.personality_type).to eq("ESTJ")
      expect(result.scores).to eq(
        "E" => 11,
        "I" => 0,
        "S" => 9,
        "N" => 0,
        "T" => 9,
        "F" => 0,
        "J" => 11,
        "P" => 0,
      )
      expect(result.attributes.keys).not_to include("answers")
    end

    it "stores the active 93-question source and resolves score ties using the existing rules" do
      result =
        described_class.record!(
          user: user,
          variant: "93",
          version: "isbf-3",
          attempt_id: attempt_id,
          answers: (1..93).map { |question_id| { id: question_id, choice: 1 } },
        )

      expect(result.reload).to have_attributes(
        variant: "93",
        scoring_version: "isbf-3",
        source_commit: "9960e585c4a949f3138eaff21494b1f99c3ba5db",
        personality_type: "ENTP",
      )
      expect(result.dimensions.select { |dimension| dimension[:tied] }).to contain_exactly(
        include(key: "SN", first_percent: 50, second_percent: 50),
        include(key: "JP", first_percent: 50, second_percent: 50),
      )
    end

    it "preserves historical scores when an earlier-version attempt is retried" do
      historical_answers = (1..93).map { |question_id| [question_id, 1] }
      historical =
        described_class.create!(
          user: user,
          variant: "93",
          scoring_version: "isbf-1",
          source_commit: "daaf70bfa171fb5487b59cf9f03455dfa2dd9f22",
          personality_type: "ENFJ",
          scores: {
            "E" => 15,
            "I" => 6,
            "S" => 9,
            "N" => 16,
            "T" => 9,
            "F" => 13,
            "J" => 14,
            "P" => 11,
          },
          attempt_id: attempt_id,
          submission_digest:
            Digest::SHA256.hexdigest(JSON.generate(["93", "isbf-1", historical_answers])),
        )
      stored_attributes = historical.attributes

      expect do
        described_class.record!(
          user: user,
          variant: "93",
          version: "isbf-1",
          attempt_id: attempt_id,
          answers:
            historical_answers.map { |question_id, choice| { id: question_id, choice: choice } },
        )
      end.to raise_error(IsbfMbti::Questionnaire::StaleVersion)

      expect(described_class.where(user_id: user.id).count).to eq(1)
      expect(historical.reload.attributes).to eq(stored_attributes)
    end

    it "rejects changed answers for an existing attempt and keeps the saved result" do
      result =
        described_class.record!(
          user: user,
          variant: "40",
          version: "isbf-2",
          attempt_id: attempt_id,
          answers: answers,
        )
      changed = answers.map { |answer| answer.merge(choice: 2) }
      expect do
        described_class.record!(
          user: user,
          variant: "40",
          version: "isbf-2",
          attempt_id: attempt_id,
          answers: changed,
        )
      end.to raise_error(described_class::SubmissionConflict)
      expect(result.reload.personality_type).to eq("ESTJ")
    end

    it "keeps the attempt namespace private to each account" do
      other = Fabricate(:user)
      first =
        described_class.record!(
          user: user,
          variant: "40",
          version: "isbf-2",
          attempt_id: attempt_id,
          answers: answers,
        )
      second =
        described_class.record!(
          user: other,
          variant: "40",
          version: "isbf-2",
          attempt_id: attempt_id,
          answers: answers,
        )
      expect(first.id).not_to eq(second.id)
      expect([first.user_id, second.user_id]).to contain_exactly(user.id, other.id)
    end

    it "rejects invalid attempts before writing history" do
      expect do
        described_class.record!(
          user: user,
          variant: "40",
          version: "isbf-2",
          attempt_id: "not-a-uuid",
          answers: answers,
        )
      end.to raise_error(IsbfMbti::Questionnaire::InvalidAnswers)
      expect(described_class.where(user_id: user.id)).to be_empty
    end
  end

  describe "#dimensions" do
    it "normalizes each actual dimension total and labels ties without a false majority" do
      result =
        described_class.new(
          scores: {
            "E" => 5,
            "I" => 6,
            "S" => 4,
            "N" => 5,
            "T" => 3,
            "F" => 6,
            "J" => 5,
            "P" => 6,
          },
        )
      expect(result.dimensions.map { |dimension| dimension[:first_percent] }).to eq(
        [45, 44, 33, 45],
      )
      expect(
        result.dimensions.map do |dimension|
          dimension[:first_percent] + dimension[:second_percent]
        end,
      ).to eq([100, 100, 100, 100])
      result.scores = {
        "E" => 2,
        "I" => 2,
        "S" => 3,
        "N" => 3,
        "T" => 1,
        "F" => 1,
        "J" => 4,
        "P" => 4,
      }
      expect(result.dimensions).to all(include(first_percent: 50, second_percent: 50, tied: true))
      expect(described_class.type_for(result.scores)).to eq("INFP")
    end
  end

  describe "private history cleanup" do
    it "clears results when the account is anonymized while the feature is disabled" do
      result =
        described_class.record!(
          user: user,
          variant: "40",
          version: "isbf-2",
          attempt_id: attempt_id,
          answers: answers,
        )
      SiteSetting.isbf_mbti_enabled = false
      UserAnonymizer.new(user).make_anonymous
      expect(described_class.exists?(result.id)).to eq(false)
    end

    it "rejects a request admitted before anonymization instead of recreating private history" do
      stale_user = User.find(user.id)
      UserAnonymizer.new(user).make_anonymous
      expect do
        described_class.record!(
          user: stale_user,
          variant: "40",
          version: "isbf-2",
          attempt_id: attempt_id,
          answers: answers,
        )
      end.to raise_error(described_class::AccountChanged)
      expect(described_class.where(user_id: user.id)).to be_empty
    end

    it "removes results on user deletion while the feature is disabled" do
      result =
        described_class.record!(
          user: user,
          variant: "40",
          version: "isbf-2",
          attempt_id: attempt_id,
          answers: answers,
        )
      SiteSetting.isbf_mbti_enabled = false
      user.destroy!
      expect(described_class.exists?(result.id)).to eq(false)
    end
  end
end
