# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe IsbfMbti::ResultsController do
  fab!(:user)
  fab!(:other_user, :user)
  let(:answers) { (1..28).map { |question_id| { id: question_id, choice: 1 } } }
  let(:submission) do
    { variant: "28", version: "isbf-2", attempt_id: SecureRandom.uuid, answers: answers }
  end

  let(:historical_result) do
    IsbfMbti::Result.create!(
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
      attempt_id: SecureRandom.uuid,
      submission_digest:
        Digest::SHA256.hexdigest(
          JSON.generate(["93", "isbf-1", (1..93).map { |question_id| [question_id, 1] }]),
        ),
    )
  end

  let(:historical_v2_result) do
    IsbfMbti::Result.create!(
      user: user,
      variant: "93",
      scoring_version: "isbf-2",
      source_commit: "daaf70bfa171fb5487b59cf9f03455dfa2dd9f22",
      personality_type: "ENFJ",
      scores: {
        "E" => 15,
        "I" => 6,
        "S" => 9,
        "N" => 16,
        "T" => 8,
        "F" => 14,
        "J" => 14,
        "P" => 11,
      },
      attempt_id: SecureRandom.uuid,
      submission_digest:
        Digest::SHA256.hexdigest(
          JSON.generate(["93", "isbf-2", (1..93).map { |question_id| [question_id, 1] }]),
        ),
    )
  end

  before { SiteSetting.isbf_mbti_enabled = true }

  def save_result(owner, choice = 1)
    IsbfMbti::Result.record!(
      user: owner,
      variant: "28",
      version: "isbf-2",
      attempt_id: SecureRandom.uuid,
      answers: (1..28).map { |question_id| { id: question_id, choice: choice } },
    )
  end

  describe "#create" do
    it "requires native authentication" do
      post "/isbf/api/mbti/results.json", params: submission, as: :json
      expect(response.status).to eq(403)
      expect(IsbfMbti::Result.count).to eq(0)
    end

    it "saves a server-computed result and returns the same result after retry" do
      sign_in(user)
      post "/isbf/api/mbti/results.json",
           params: submission.merge(type: "INFP", user_id: other_user.id),
           as: :json
      expect(response.status).to eq(201)
      result = response.parsed_body.fetch("result")
      expect(result).to include(
        "type" => "ESTJ",
        "variant" => "28",
        "version" => "isbf-2",
        "source_commit" => IsbfMbti::Questionnaire.fetch("28").source_commit,
      )
      expect(result.fetch("dimensions").map { |dimension| dimension.fetch("key") }).to eq(
        IsbfMbti::Questionnaire::DIMENSIONS,
      )
      expect(IsbfMbti::Result.find(result["id"]).user_id).to eq(user.id)
      expect(result.keys).not_to include("answers", "attempt_id", "submission_digest", "user_id")
      expect(response.headers["Cache-Control"]).to include("no-store")
      post "/isbf/api/mbti/results.json", params: submission, as: :json
      expect(response.parsed_body.fetch("result")).to eq(result)
      expect(IsbfMbti::Result.where(user_id: user.id).count).to eq(1)
    end

    it "reports invalid answers and stale or conflicting submissions without extra histories" do
      sign_in(user)
      post "/isbf/api/mbti/results.json", params: submission.merge(answers: []), as: :json
      expect(response.status).to eq(422)
      post "/isbf/api/mbti/results.json", params: submission.merge(version: "old"), as: :json
      expect(response.status).to eq(409)
      expect(IsbfMbti::Result.count).to eq(0)
      post "/isbf/api/mbti/results.json", params: submission, as: :json
      changed = submission.merge(answers: answers.map { |answer| answer.merge(choice: 2) })
      post "/isbf/api/mbti/results.json", params: changed, as: :json
      expect(response.status).to eq(409)
      expect(IsbfMbti::Result.count).to eq(1)
    end

    it "returns Chinese errors for a Chinese member on an English-default site" do
      SiteSetting.default_locale = "en"
      SiteSetting.allow_user_locale = true
      user.update!(locale: "zh_CN")
      sign_in(user)

      post "/isbf/api/mbti/results.json", params: submission.merge(answers: []), as: :json
      expect(response.status).to eq(422)
      expect(response.parsed_body.fetch("errors")).to eq(["请为每道题选择一个有效选项后再提交。"])

      post "/isbf/api/mbti/results.json", params: submission.merge(version: "isbf-1"), as: :json

      expect(response.status).to eq(409)
      expected_error = "题库版本已更新，请使用当前版本重新开始测试。"
      expect(response.parsed_body.fetch("errors")).to eq([expected_error])

      post "/isbf/api/mbti/results.json", params: submission, as: :json
      expect(response.status).to eq(201)
      changed = submission.merge(answers: answers.map { |answer| answer.merge(choice: 2) })
      post "/isbf/api/mbti/results.json", params: changed, as: :json
      expect(response.status).to eq(409)
      expect(response.parsed_body.fetch("errors")).to eq(["本次测试已保存，提交的答案与原记录不同，请重新开始测试。"])
    end

    it "rejects earlier-version submissions without rewriting or adding history" do
      sign_in(user)
      stored_attributes = historical_result.attributes
      stale_submission = {
        variant: "93",
        version: "isbf-1",
        attempt_id: historical_result.attempt_id,
        answers: (1..93).map { |question_id| { id: question_id, choice: 1 } },
      }

      [historical_result.attempt_id, SecureRandom.uuid].each do |attempt_id|
        post "/isbf/api/mbti/results.json",
             params: stale_submission.merge(attempt_id: attempt_id),
             as: :json

        expect(response.status).to eq(409)
        expect(response.parsed_body.fetch("errors")).to eq([I18n.t("isbf_mbti.stale_version")])
      end

      expect(IsbfMbti::Result.where(user_id: user.id).count).to eq(1)
      expect(historical_result.reload.attributes).to eq(stored_attributes)
    end

    it "returns a stale-version error for isbf-2 93-question retries and unsubmitted attempts" do
      sign_in(user)
      stored_attributes = historical_v2_result.attributes
      stale_submission = {
        variant: "93",
        version: "isbf-2",
        answers: (1..93).map { |question_id| { id: question_id, choice: 1 } },
      }

      [historical_v2_result.attempt_id, SecureRandom.uuid].each do |attempt_id|
        post "/isbf/api/mbti/results.json",
             params: stale_submission.merge(attempt_id: attempt_id),
             as: :json

        expect(response.status).to eq(409)
        expect(response.parsed_body.fetch("errors")).to eq([I18n.t("isbf_mbti.stale_version")])
      end

      expect(IsbfMbti::Result.where(user_id: user.id).count).to eq(1)
      expect(historical_v2_result.reload.attributes).to eq(stored_attributes)
    end

    it "uses the native write rate limiter" do
      sign_in(user)
      RateLimiter.enable
      30.times do
        post "/isbf/api/mbti/results.json", params: submission, as: :json
        expect(response.status).to eq(201)
      end
      post "/isbf/api/mbti/results.json", params: submission, as: :json
      expect(response.status).to eq(429)
      expect(IsbfMbti::Result.where(user_id: user.id).count).to eq(1)
    ensure
      RateLimiter.disable
    end
  end

  describe "#index" do
    it "paginates newest-first history for the owner only" do
      foreign = save_result(other_user, 2)
      own = Array.new(21) { save_result(user) }
      sign_in(user)
      get "/isbf/api/mbti/results.json", params: { page: 0, user_id: other_user.id }
      expect(response.status).to eq(200)
      result = response.parsed_body
      expect(result["results"].map { |record| record["id"] }).to eq(own.reverse.first(20).map(&:id))
      expect(result["results"].map { |record| record["id"] }).not_to include(foreign.id)
      expect(result["has_more"]).to eq(true)
      get "/isbf/api/mbti/results.json", params: { page: 1 }
      expect(response.parsed_body["results"].map { |record| record["id"] }).to eq([own.first.id])
      expect(response.parsed_body["has_more"]).to eq(false)
    end

    it "allows no history access for guests" do
      get "/isbf/api/mbti/results.json"
      expect(response.status).to eq(403)
    end
  end

  describe "#show" do
    it "exposes only the signed-in owner's result" do
      own = save_result(user)
      foreign = save_result(other_user)
      sign_in(user)
      get "/isbf/api/mbti/results/#{own.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("result")).to include(
        "id" => own.id,
        "type" => own.personality_type,
        "version" => own.scoring_version,
        "source_commit" => own.source_commit,
      )
      get "/isbf/api/mbti/results/#{foreign.id}.json"
      expect(response.status).to eq(404)
    end

    it "returns the exact stored version, scores and type of an earlier result" do
      sign_in(user)
      get "/isbf/api/mbti/results/#{historical_result.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("result")).to include(
        "id" => historical_result.id,
        "variant" => "93",
        "version" => "isbf-1",
        "source_commit" => "daaf70bfa171fb5487b59cf9f03455dfa2dd9f22",
        "type" => "ENFJ",
        "scores" => {
          "E" => 15,
          "I" => 6,
          "S" => 9,
          "N" => 16,
          "T" => 9,
          "F" => 13,
          "J" => 14,
          "P" => 11,
        },
      )
    end

    it "returns the stored result from the previous 93-question bank" do
      sign_in(user)
      get "/isbf/api/mbti/results/#{historical_v2_result.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("result")).to include(
        "id" => historical_v2_result.id,
        "variant" => "93",
        "version" => "isbf-2",
        "source_commit" => "daaf70bfa171fb5487b59cf9f03455dfa2dd9f22",
        "type" => "ENFJ",
        "scores" => historical_v2_result.scores,
      )
    end

    it "keeps other users' history private from staff" do
      foreign = save_result(user)
      [Fabricate(:moderator), Fabricate(:admin)].each do |staff|
        sign_in(staff)
        get "/isbf/api/mbti/results/#{foreign.id}.json"
        expect(response.status).to eq(404)
      end
    end
  end

  describe "#destroy" do
    it "deletes only an owned history and leaves other accounts intact" do
      own = save_result(user)
      foreign = save_result(other_user)
      sign_in(user)
      delete "/isbf/api/mbti/results/#{foreign.id}.json"
      expect(response.status).to eq(404)
      expect(IsbfMbti::Result.exists?(foreign.id)).to eq(true)
      delete "/isbf/api/mbti/results/#{own.id}.json"
      expect(response.status).to eq(204)
      expect(IsbfMbti::Result.exists?(own.id)).to eq(false)
      expect(IsbfMbti::Result.exists?(foreign.id)).to eq(true)
    end
  end
end
