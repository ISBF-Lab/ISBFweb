# frozen_string_literal: true

require "digest"

module IsbfMbti
  class Result < ActiveRecord::Base
    self.table_name = "isbf_mbti_results"

    class SubmissionConflict < StandardError
    end

    class AccountChanged < StandardError
    end

    belongs_to :user
    validates :variant,
              :scoring_version,
              :source_commit,
              :personality_type,
              :scores,
              :attempt_id,
              :submission_digest,
              presence: true

    def self.record!(user:, variant:, version:, attempt_id:, answers:)
      unless attempt_id.is_a?(String) &&
               attempt_id.match?(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i)
        raise Questionnaire::InvalidAnswers
      end

      identity = [user.username, user.active, user.suspended_till]
      questionnaire = Questionnaire.fetch(variant)
      normalized = questionnaire.normalize_answers(answers, submitted_version: version)
      digest = Digest::SHA256.hexdigest(JSON.generate([questionnaire.variant, version, normalized]))

      user.with_lock do
        raise AccountChanged unless identity == [user.username, user.active, user.suspended_till]
        existing = find_by(user_id: user.id, attempt_id: attempt_id.downcase)
        if existing
          raise SubmissionConflict unless existing.submission_digest == digest
          next existing
        end

        counts = questionnaire.score(normalized)
        create!(
          user: user,
          variant: questionnaire.variant,
          scoring_version: questionnaire.version,
          source_commit: questionnaire.source_commit,
          scores: counts,
          personality_type: type_for(counts),
          attempt_id: attempt_id.downcase,
          submission_digest: digest,
        )
      end
    end

    def self.type_for(scores)
      Questionnaire::DIMENSIONS
        .map do |dimension|
          first, second = dimension.chars
          scores.fetch(first) > scores.fetch(second) ? first : second
        end
        .join
    end

    def dimensions
      Questionnaire::DIMENSIONS.map do |dimension|
        first, second = dimension.chars
        first_count = scores.fetch(first)
        second_count = scores.fetch(second)
        first_percent = (100.0 * first_count / (first_count + second_count)).round
        {
          key: dimension,
          first: first,
          second: second,
          first_count: first_count,
          second_count: second_count,
          first_percent: first_percent,
          second_percent: 100 - first_percent,
          tied: first_count == second_count,
        }
      end
    end
  end
end
