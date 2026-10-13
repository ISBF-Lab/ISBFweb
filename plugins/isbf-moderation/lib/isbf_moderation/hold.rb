# frozen_string_literal: true

module IsbfModeration
  module Hold
    FIELD = "isbf_severe_report_reviewable_id"
    PENDING = "isbf_severe_report_pending"
    LATEST = "isbf_severe_report_latest_at"
    SCORES = "isbf_severe_report_score_ids"

    def self.active?(post)
      return false unless post&.hidden?
      if !post.custom_fields_preloaded? || post.custom_field_preloaded?(FIELD)
        return post.custom_fields[FIELD].present?
      end

      persisted?(post)
    end

    # Mutation guards use the database so stale model/custom field caches cannot release a hold.
    def self.persisted?(post)
      post && PostCustomField.exists?(post_id: post.id, name: FIELD)
    end

    def self.set!(post, reviewable)
      post.custom_fields[FIELD] = reviewable.id
      post.save_custom_fields
    end

    def self.clear!(post)
      PostCustomField.where(post_id: post.id, name: FIELD).delete_all
      post.clear_custom_fields
    end

    def self.notice
      I18n.t("isbf_moderation.held_notice")
    end
  end
end
