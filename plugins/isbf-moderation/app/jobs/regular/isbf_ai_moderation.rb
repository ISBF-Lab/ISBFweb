# frozen_string_literal: true

module Jobs
  class IsbfAiModeration < ::Jobs::Base
    def execute(args)
      ::IsbfModeration::AiScanner.scan(
        args[:post_id],
        attempt: args[:attempt].to_i,
        expected_fingerprint: args[:fingerprint],
      )
    end
  end
end
