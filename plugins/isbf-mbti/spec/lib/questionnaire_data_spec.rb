# frozen_string_literal: true

require_relative "../plugin_helper"
require "digest"

RSpec.describe IsbfMbti::Questionnaire do
  it "retains exact upstream bytes, complete bilingual questions and audited option directions" do
    root = File.expand_path("../../data", __dir__)
    hashes = {
      "28" => "a49e693e134d4cfe18149e675b05fb679471e9a5283d2846ed41cfdc8f52aaa9",
      "40" => "492cccf54baab11a55e37ea012eac4668a04f682a55ed196e79842242747616f",
      "93" => "b14875063cd60664c36e6264777fcff59713ba7fdce9da072eace1f488d0e479",
    }
    audit = JSON.parse(File.read(File.join(root, "scoring.json")))
    expect(audit["source_commit"]).to eq("daaf70bfa171fb5487b59cf9f03455dfa2dd9f22")
    expect(audit["scoring_version"]).to eq("isbf-2")
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
      "1aa502a8586cdf4a8100309d94069606396d79dd87410947d2d830de81aaac47",
    )
  end

  it "pins the exact zcw93 question and license bytes and their scoring provenance" do
    root = File.expand_path("../../data/zcw93", __dir__)
    audit = JSON.parse(File.read(File.join(root, "scoring.json")))
    expect(audit).to include(
      "source_commit" => "9960e585c4a949f3138eaff21494b1f99c3ba5db",
      "scoring_version" => "isbf-3",
    )
    hashes = {
      "data/questions_standard_mbti_93.json" =>
        "5e699d6c35a3c3787456392834acbfe9d537f60dcc52ade62ecd1d9240d32f8a",
      "mbti/services_standard.py" =>
        "9f8f158462eb5426d2a72150709466b4c1ce9310c3f464b3b21eaaa0b622ee7e",
      "LICENSE" => "3bed3331b7048bac17cf50e249d560ccc9508c970da8d7b9283bf4f2e633a91d",
    }
    expect(audit.fetch("sources").transform_values { |source| source.fetch("sha256") }).to eq(
      hashes,
    )
    %w[data/questions_standard_mbti_93.json LICENSE].each do |source|
      expect(Digest::SHA256.file(File.join(root, File.basename(source))).hexdigest).to eq(
        hashes.fetch(source),
      )
    end
  end

  it "retains all 93 raw Chinese A/B questions and their paired scoring directions" do
    root = File.expand_path("../../data/zcw93", __dir__)
    questions = JSON.parse(File.read(File.join(root, "questions_standard_mbti_93.json")))
    expect(questions.map { |question| question.fetch("id") }).to eq((1..93).to_a)
    variants = JSON.parse(File.read(File.join(root, "scoring.json"))).fetch("variants")
    expect(variants.keys).to contain_exactly("93")
    mapping = variants.fetch("93")
    expect(mapping.keys).to contain_exactly(*(1..93).map(&:to_s))

    questions.each do |question|
      expect(question.keys).to contain_exactly("id", "question", "optionA", "optionB")
      expect(question.values_at("question", "optionA", "optionB")).to all(be_present)
      direction = mapping.fetch(question.fetch("id").to_s)
      expect(described_class::DIMENSIONS).to include(direction.fetch("dimension"))
      expect(direction.fetch("poles")).to contain_exactly(*direction.fetch("dimension").chars)
    end

    first_poles = (1..93).map { |id| mapping.fetch(id.to_s).fetch("poles").first }
    expect(first_poles.join).to eq(
      "JSEJNFEPSENJIJFIPNEJFNEPSINJFSTETSTJFISFJITNTNTNTSFSFSPTITPSTESJNTNINFNFSETJIPEPENEPIJTPFPISP",
    )
  end
end
