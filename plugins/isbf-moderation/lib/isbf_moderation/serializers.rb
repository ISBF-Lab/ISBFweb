# frozen_string_literal: true

module IsbfModeration
  module BasicPostProtection
    def cooked
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object)
        return Hold.notice
      end
      super
    end
  end

  module PostSerializerProtection
    def raw
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object)
        return nil
      end
      super
    end

    def excerpt
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object)
        return Hold.notice
      end
      super
    end

    def edit_reason
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object)
        return nil
      end
      object.edit_reason
    end
  end

  module TopicViewSerializerProtection
    def image_url
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object.topic.first_post)
        return nil
      end
      super
    end

    def thumbnails
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object.topic.first_post)
        return nil
      end
      super
    end
  end

  module TopicSerializerProtection
    def excerpt
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object.first_post)
        return Hold.notice
      end
      super
    end

    def image_url
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object.first_post)
        return nil
      end
      super
    end

    def thumbnails
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object.first_post)
        return nil
      end
      super
    end
  end

  module ReviewSerializerProtection
    def cooked
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object.post)
        return Hold.notice
      end
      super
    end

    def raw
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object.post)
        return nil
      end
      super
    end

    def reviewable_notes
      if !(
           scope.is_staff? ||
             (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
         ) && Hold.active?(object.post)
        return []
      end
      object.reviewable_notes
    end
  end

  module ScoreSerializerProtection
    def reason
      return nil if isbf_restricted_score?
      details = Audit.details(object)
      return super if details.blank?

      label = CGI.escapeHTML(I18n.t("isbf_moderation.severe_label"))
      explanation = CGI.escapeHTML(details.fetch("reason"))
      "<p>#{label}: #{explanation}</p>#{super}"
    end

    def reason_data
      return nil if isbf_restricted_score?
      super
    end

    def include_reviewable_conversation?
      return false if isbf_restricted_score?
      super
    end

    private

    def isbf_restricted_score?
      !(
        scope.is_staff? || (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
      ) && object.reviewable.is_a?(ReviewableFlaggedPost) && Hold.active?(object.reviewable.post)
    end

    def watched_words_found
      details = Audit.details(object)
      return super unless details
      details["original_context"]&.split(",")&.map(&:downcase)&.uniq || []
    end
  end

  module UserActionProtection
    def excerpt
      return Hold.notice if isbf_held_excerpt?
      super
    end

    def cooked
      return Hold.notice if isbf_held_excerpt?
      super
    end

    def edit_reason
      return nil if isbf_held_excerpt?
      object.edit_reason
    end

    private

    def isbf_held_excerpt?
      if scope.is_staff? ||
           (scope.respond_to?(:academy_can?) && scope.academy_can?(:hidden_content))
        return false
      end
      return object.isbf_severe_report_held? if object.respond_to?(:isbf_severe_report_held?)
      return @isbf_held_excerpt if defined?(@isbf_held_excerpt)
      post_id = object.respond_to?(:cooked_post_id) ? object.cooked_post_id : object.post_id
      @isbf_held_excerpt = post_id && PostCustomField.exists?(post_id: post_id, name: Hold::FIELD)
    end
  end

  module ActivityHoldPreloader
    def stream(options = nil)
      records = super
      if records.empty? || options&.dig(:guardian)&.is_staff? ||
           (
             options&.dig(:guardian).respond_to?(:academy_can?) &&
               options[:guardian].academy_can?(:hidden_content)
           )
        return records
      end

      post_ids =
        records.filter_map { |record| record.cooked_post_id if record.respond_to?(:cooked_post_id) }
      held_ids = PostCustomField.where(post_id: post_ids, name: Hold::FIELD).pluck(:post_id).to_set
      records.each do |record|
        post_id = record.respond_to?(:cooked_post_id) ? record.cooked_post_id : nil
        held = held_ids.include?(post_id)
        record.define_singleton_method(:isbf_severe_report_held?) { held }
      end
      records
    end
  end
end
