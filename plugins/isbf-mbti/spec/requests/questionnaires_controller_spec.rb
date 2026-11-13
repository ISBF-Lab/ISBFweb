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
      expect(
        summaries.map { |summary| summary.values_at("variant", "version", "source_commit") },
      ).to eq(
        [
          %w[28 isbf-2 daaf70bfa171fb5487b59cf9f03455dfa2dd9f22],
          %w[40 isbf-2 daaf70bfa171fb5487b59cf9f03455dfa2dd9f22],
          %w[93 isbf-3 9960e585c4a949f3138eaff21494b1f99c3ba5db],
        ],
      )
      expect(summaries.map { |summary| summary["question_count"] }).to eq([28, 40, 93])
      expect(summaries.map { |summary| summary.keys }).to all(
        contain_exactly("variant", "question_count", "version", "source_commit"),
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

    it "returns the exact Chinese question and A/B option text for the active 93-question bank" do
      source = File.expand_path("../../data/zcw93/questions_standard_mbti_93.json", __dir__)
      questions = JSON.parse(File.binread(source))
      sign_in(user)
      get "/isbf/api/mbti/questionnaires/93.json"

      expect(response.status).to eq(200)
      questionnaire = response.parsed_body.fetch("questionnaire")
      expect(questionnaire.keys).to contain_exactly(
        "variant",
        "question_count",
        "version",
        "source_commit",
        "questions",
      )
      expect(questionnaire).to include(
        "variant" => "93",
        "question_count" => 93,
        "version" => "isbf-3",
        "source_commit" => "9960e585c4a949f3138eaff21494b1f99c3ba5db",
      )
      expect(questionnaire.fetch("questions")).to eq(
        questions.map do |question|
          question.slice("id", "question").merge(
            "options" => question.values_at("optionA", "optionB"),
          )
        end,
      )
    end
  end
end
