# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe IsbfMbti::QuestionnairesController do
  fab!(:user)

  let(:maintenance) do
    Module.new do
      mattr_accessor :paused, default: false

      def self.ensure_available!(key)
        raise Discourse::NotFound if key == "mbti" && paused
      end
    end
  end

  around { |example| stub_const(Object, :IsbfWorkbenchMaintenance, maintenance) { example.run } }

  before do
    SiteSetting.isbf_mbti_enabled = true
    sign_in(user)
  end

  describe "#index" do
    it "closes the page, questionnaire and result APIs until maintenance ends" do
      maintenance.paused = true
      %w[/isbf/mbti /isbf/api/mbti/questionnaires.json /isbf/api/mbti/results.json].each do |url|
        get url
        expect(response.status).to eq(404)
      end
      post "/isbf/api/mbti/results.json", params: { variant: "40", answers: [] }
      expect(response.status).to eq(404)

      maintenance.paused = false
      get "/isbf/mbti"
      expect(response.status).to eq(200)
      get "/isbf/api/mbti/questionnaires.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.fetch("questionnaires").size).to eq(3)
      expect(SiteSetting.isbf_mbti_enabled).to eq(true)
    end
  end
end
