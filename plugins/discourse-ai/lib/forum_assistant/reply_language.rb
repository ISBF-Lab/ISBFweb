# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    module ReplyLanguage
      def self.for_question(question, user:, language: nil, previous_questions: [])
        detected = language.to_s.tr("-", "_")
        text = prose(question).presence || question.to_s
        return "zh_CN" if chinese?(text)
        return "en" if english_sentence?(text)
        return detected if detected.present? && I18n.locale_available?(detected)

        previous_questions.reverse_each do |previous_question|
          previous_text = prose(previous_question)
          return "zh_CN" if chinese?(previous_text)
          return "en" if english_sentence?(previous_text)
        end
        user.effective_locale
      end

      def self.chinese?(text)
        text.match?(/\p{Han}/) && !text.match?(/[\p{Hiragana}\p{Katakana}\p{Hangul}]/) &&
          !english_sentence?(text)
      end

      def self.english_sentence?(text)
        text.match?(
          /\A\s*(where|what|when|which|who|how|why|is|are|do|does|did|can|could|please|find|show|list|tell|i)\b/i,
        ) && text.scan(/\p{Latin}+/).length >= [3, text.scan(/\p{Han}/).length].max
      end

      def self.prose(text)
        text.to_s.gsub(%r{\x60[^\x60]*\x60|https?://\S+}i, " ").strip
      end

      def self.chinese_reply?(text)
        text = prose(text.gsub(/\[[^\]]*\]\([^)]*\)|[“"][^”"]*[”"]/, " "))
        chinese?(text) && text.scan(/\p{Han}/).length >= text.scan(/\p{Latin}+/).length
      end

      def self.translation_locale(locale)
        locale.to_s.start_with?("zh") ? :zh_CN : :en
      end
    end
  end
end
