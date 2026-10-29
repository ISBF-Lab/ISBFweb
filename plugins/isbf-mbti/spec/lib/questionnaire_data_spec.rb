# frozen_string_literal: true

require_relative "../plugin_helper"
require "digest"

RSpec.describe "MBTI questionnaire provenance" do
  it "retains exact upstream bytes, complete bilingual questions and audited option directions" do
    root = File.expand_path("../../data", __dir__)
    hashes = {
      "28" => "a49e693e134d4cfe18149e675b05fb679471e9a5283d2846ed41cfdc8f52aaa9",
      "40" => "492cccf54baab11a55e37ea012eac4668a04f682a55ed196e79842242747616f",
      "93" => "b14875063cd60664c36e6264777fcff59713ba7fdce9da072eace1f488d0e479"
    }
    audit = JSON.parse(File.read(File.join(root, "scoring.json")))
    expect(audit["source_commit"]).to eq("daaf70bfa171fb5487b59cf9f03455dfa2dd9f22")
    expect(audit["scoring_version"]).to eq("isbf-1")
    expect(audit["variants"].keys).to contain_exactly("28", "40", "93")
    hashes.each do |variant, expected_hash|
      source = File.join(root, "upstream", "questions_#{variant}.json")
      expect(Digest::SHA256.file(source).hexdigest).to eq(expected_hash)
      questions = JSON.parse(File.read(source)).fetch("MBTI_questions")
      expect(questions.map { |question| question["id"] }).to eq((1..variant.to_i).to_a)
      mapping = audit.fetch("variants").fetch(variant)
      expect(mapping.keys.map(&:to_i)).to contain_exactly(*(1..variant.to_i))
      questions.each do |question|
        %w[zh en].each do |language|
          expect(question.fetch("question").fetch(language)).to be_present
          options = question.fetch("options").fetch(language)
          expect(options.size).to eq(2)
          expect(options).to all(be_present)
        end
        direction = mapping.fetch(question.fetch("id").to_s)
        expect(IsbfMbti::Questionnaire::DIMENSIONS).to include(direction["dimension"])
        expect(direction["poles"]).to contain_exactly(*direction["dimension"].chars)
      end
    end
    expect(Digest::SHA256.file(File.join(root, "upstream", "LICENSE")).hexdigest).to eq(
      "1aa502a8586cdf4a8100309d94069606396d79dd87410947d2d830de81aaac47"
    )
  end
end
