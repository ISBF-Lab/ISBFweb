# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe IsbfMbti::QuestionnairesController do
  fab!(:user)
  before { SiteSetting.isbf_mbti_enabled = true }

  describe "#index" do
    it "exposes only the three current questionnaire summaries to a guest" do
      get "/isbf/api/mbti/questionnaires.json"
      expect(response.status).to eq(200)
      summaries = response.parsed_body.fetch("questionnaires")
      expect(summaries.map { |summary| summary["variant"] }).to eq(%w[28 40 93])
      expect(summaries.map { |summary| summary["question_count"] }).to eq([28, 40, 93])
      expect(summaries.map { |summary| summary.keys }).to all(
        contain_exactly("variant", "question_count", "version", "source_commit")
      )
    end

    it "closes the API when the feature is off" do
      SiteSetting.isbf_mbti_enabled = false
      get "/isbf/api/mbti/questionnaires.json"
      expect(response.status).to eq(404)
    end
  end

  describe "#show" do
    it "requires login before starting a test" do
      get "/isbf/api/mbti/questionnaires/40.json"
      expect(response.status).to eq(403)
    end

    it "returns escaped plain question data without exposing any user history" do
      sign_in(user)
      get "/isbf/api/mbti/questionnaires/93.json"
      expect(response.status).to eq(200)
      questionnaire = response.parsed_body.fetch("questionnaire")
      expect(questionnaire["questions"].size).to eq(93)
      expect(questionnaire["questions"].first.keys).to contain_exactly("id", "question", "options")
      expect(questionnaire["version"]).to eq("isbf-1")
      expect(questionnaire["source_commit"]).to eq("daaf70bfa171fb5487b59cf9f03455dfa2dd9f22")
    end
  end
end
