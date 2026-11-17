# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    module PostValidatorExtension
      def stripped_length(post)
        return super unless forum_assistant_question?(post)

        StrippedLengthValidator.validate(
          post,
          :raw,
          post.raw,
          1..SiteSetting.ai_forum_assistant_max_question_chars,
          strip_uploads: true,
        )
      end

      private

      def raw_quality(post)
        return if forum_assistant_question?(post)
        super
      end

      def forum_assistant_question?(post)
        Configuration.enabled? &&
          (
            Policy.managed_topic?(post.topic) ||
              post.instance_variable_get(:@forum_assistant_question)
          )
      end
    end
  end
end
