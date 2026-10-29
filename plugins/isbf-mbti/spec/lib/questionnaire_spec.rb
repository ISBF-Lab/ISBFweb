# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe IsbfMbti::Questionnaire do
  describe "#normalize_answers" do
    let(:questionnaire) { described_class.fetch("40") }
    let(:answers) { (1..40).map { |question_id| { id: question_id, choice: 1 } } }

    it "accepts complete form-encoded and shuffled answers" do
      submitted = answers.reverse.map { |answer| answer.transform_values(&:to_s) }
      normalized = questionnaire.normalize_answers(submitted, submitted_version: "isbf-1")
      expect(normalized).to eq((1..40).map { |question_id| [question_id, 1] })
    end

    it "rejects incomplete, duplicate, unknown and malformed selections" do
      invalid = [
        nil,
        {},
        answers.first(39),
        answers + [{ id: 41, choice: 1 }],
        answers.first(39) + [{ id: 39, choice: 1 }],
        answers.first(39) + [{ id: 999, choice: 1 }],
        answers.first(39) + [{ id: 40, choice: 0 }],
        answers.first(39) + [{ id: 40, choice: 3 }],
        answers.first(39) + [{ id: 40, choice: 1.0 }],
        answers.first(39) + [{ id: true, choice: 1 }],
        answers.first(39) + [{ id: "40oops", choice: 1 }],
        answers.first(39) + [{ id: 40, choice: "01" }],
        answers.first(39) + [{ id: 40, choice: 1, score: "E" }],
      ]
      invalid.each do |submitted|
        expect do
          questionnaire.normalize_answers(submitted, submitted_version: "isbf-1")
        end.to raise_error(described_class::InvalidAnswers)
      end
    end

    it "requires the exact published scoring version" do
      expect do
        questionnaire.normalize_answers(answers, submitted_version: "old")
      end.to raise_error(described_class::StaleVersion)
    end
  end

  describe "#score" do
    it "uses audited directions and the actual dimension sizes for all variants" do
      expected = {
        "28" => {
          "E" => 7,
          "I" => 0,
          "S" => 7,
          "N" => 0,
          "T" => 7,
          "F" => 0,
          "J" => 7,
          "P" => 0,
        },
        "40" => {
          "E" => 11,
          "I" => 0,
          "S" => 9,
          "N" => 0,
          "T" => 9,
          "F" => 0,
          "J" => 11,
          "P" => 0,
        },
        "93" => {
          "E" => 15,
          "I" => 6,
          "S" => 9,
          "N" => 16,
          "T" => 9,
          "F" => 13,
          "J" => 14,
          "P" => 11,
        },
      }
      expected.each do |variant, scores|
        questionnaire = described_class.fetch(variant)
        first = (1..variant.to_i).map { |question_id| [question_id, 1] }
        expect(questionnaire.score(first)).to eq(scores)
        second = first.map { |question_id, _| [question_id, 2] }
        opposite = {
          "E" => "I",
          "I" => "E",
          "S" => "N",
          "N" => "S",
          "T" => "F",
          "F" => "T",
          "J" => "P",
          "P" => "J",
        }
        expect(questionnaire.score(second)).to eq(
          scores.transform_keys { |pole| opposite.fetch(pole) },
        )
      end
    end

    it "scores preferring a few close friends toward I in the 93-question version" do
      questionnaire = described_class.fetch("93")
      first = (1..93).map { |question_id| [question_id, 1] }
      other = first.map { |question_id, choice| [question_id, question_id == 1 ? 2 : choice] }
      original = questionnaire.score(first)
      changed = questionnaire.score(other)
      expect(changed).to eq(original.merge("I" => original["I"] - 1, "E" => original["E"] + 1))
    end
  end

  describe ".fetch" do
    it "rejects variants outside the pinned set" do
      [nil, "../../etc/passwd", "41", "40.0", {}].each do |variant|
        expect { described_class.fetch(variant) }.to raise_error(Discourse::InvalidParameters)
      end
    end
  end
end
