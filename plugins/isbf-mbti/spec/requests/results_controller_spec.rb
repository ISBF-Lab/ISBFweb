# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe IsbfMbti::ResultsController do
  fab!(:user)
  fab!(:other_user, :user)
  let(:answers) { (1..28).map { |question_id| { id: question_id, choice: 1 } } }
  let(:submission) do
    { variant: "28", version: "isbf-1", attempt_id: SecureRandom.uuid, answers: answers }
  end

  before { SiteSetting.isbf_mbti_enabled = true }

  def save_result(owner, choice = 1)
    IsbfMbti::Result.record!(
      user: owner,
      variant: "28",
      version: "isbf-1",
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
      expect(result["type"]).to eq("ESTJ")
      expect(IsbfMbti::Result.find(result["id"]).user_id).to eq(user.id)
      expect(result.keys).not_to include("answers", "attempt_id", "submission_digest", "user_id")
      expect(response.headers["Cache-Control"]).to include("no-store")
      post "/isbf/api/mbti/results.json", params: submission, as: :json
      expect(response.parsed_body.dig("result", "id")).to eq(result["id"])
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
      get "/isbf/api/mbti/results/#{foreign.id}.json"
      expect(response.status).to eq(404)
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
