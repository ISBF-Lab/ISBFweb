# frozen_string_literal: true

require "json"

module IsbfMbti
  class Questionnaire
    VARIANTS = %w[28 40 93].freeze
    DIMENSIONS = %w[EI SN TF JP].freeze
    DATA_PATH = File.expand_path("../../data", __dir__)
    ZCW_93_PATH = File.join(DATA_PATH, "zcw93")

    class InvalidAnswers < StandardError
    end

    class StaleVersion < StandardError
    end

    def self.fetch(variant)
      raise Discourse::InvalidParameters.new(:variant) if VARIANTS.exclude?(variant.to_s)
      @questionnaires ||= {}
      @questionnaires[variant.to_s] ||= new(variant.to_s)
    end

    attr_reader :variant, :version, :source_commit

    def initialize(variant)
      @variant = variant
      if variant == "93"
        scoring = JSON.parse(File.read(File.join(ZCW_93_PATH, "scoring.json")))
        source = File.join(ZCW_93_PATH, "questions_standard_mbti_93.json")
        @questions =
          JSON
            .parse(File.read(source))
            .map do |question|
              {
                "id" => question.fetch("id"),
                "question" => {
                  "zh" => question.fetch("question"),
                },
                "options" => {
                  "zh" => [question.fetch("optionA"), question.fetch("optionB")],
                },
              }
            end
      else
        scoring = JSON.parse(File.read(File.join(DATA_PATH, "scoring.json")))
        source = File.join(DATA_PATH, "upstream", "questions_#{variant}.json")
        @questions = JSON.parse(File.read(source)).fetch("MBTI_questions")
      end
      @version = scoring.fetch("scoring_version")
      @source_commit = scoring.fetch("source_commit")
      @mapping = scoring.fetch("variants").fetch(variant)
    end

    def metadata
      {
        variant: variant,
        question_count: @questions.size,
        version: version,
        source_commit: source_commit,
      }
    end

    def definition
      metadata.merge(
        questions:
          @questions.map do |question|
            {
              id: question.fetch("id"),
              question: question.fetch("question").fetch("zh"),
              options: question.fetch("options").fetch("zh"),
            }
          end,
      )
    end

    def normalize_answers(answers, submitted_version:)
      raise StaleVersion unless submitted_version == version
      raise InvalidAnswers unless answers.is_a?(Array) && answers.size == @questions.size

      normalized =
        answers
          .map do |answer|
            unless answer.respond_to?(:keys) && answer.keys.map(&:to_s).sort == %w[choice id]
              raise InvalidAnswers
            end
            question_id = integer(answer[:id] || answer["id"])
            choice = integer(answer[:choice] || answer["choice"])
            raise InvalidAnswers if [1, 2].exclude?(choice)
            [question_id, choice]
          end
          .sort_by(&:first)

      unless normalized.map(&:first) == @questions.map { |question| question.fetch("id") }.sort
        raise InvalidAnswers
      end
      normalized
    end

    def score(normalized)
      counts = DIMENSIONS.join.chars.to_h { |pole| [pole, 0] }
      normalized.each do |question_id, choice|
        pole = @mapping.fetch(question_id.to_s).fetch("poles").fetch(choice - 1)
        counts[pole] += 1
      end
      counts
    end

    private

    def integer(value)
      return value if value.is_a?(Integer)
      return value.to_i if value.is_a?(String) && value.match?(/\A[1-9]\d*\z/)
      raise InvalidAnswers
    end
  end
end
