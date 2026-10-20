# frozen_string_literal: true

module IsbfModeration
  module AiScanner
    PENDING_FIELD = "isbf_ai_moderation_pending"
    STATE_FIELD = "isbf_ai_moderation_state"
    APPROVED_FIELD = "isbf_ai_moderation_approved_content"
    RETRY_DELAYS = [1.minute, 5.minutes, 15.minutes].freeze
    MAX_SCANS_PER_MINUTE = 60

    def self.enabled?
      SiteSetting.isbf_ai_moderation_enabled && defined?(LlmModel) &&
        SiteSetting.discourse_ai_enabled
    end

    def self.eligible?(post)
      return false unless enabled? && Policy.forum_post?(post) && !post.hidden?
      unless post.topic.visible? && post.topic.category && !post.topic.category.read_restricted?
        return false
      end
      return false if !post.user || post.user.bot?

      excluded = []
      %i[academy_official_category isbf_learning_category_id].each do |setting|
        if SiteSetting.respond_to?(setting) &&
             (id = SiteSetting.public_send(setting).to_i).positive?
          excluded << id
          excluded.concat(Category.subcategory_ids(id))
        end
      end
      return false if excluded.include?(post.topic.category_id)

      owner = Notifications.recipient_for(post)
      groups = SiteSetting.isbf_ai_moderation_exempt_groups.split("|").map(&:to_i)
      owner = User.find_by(id: owner.id) if owner && groups.present?
      !owner || !owner.in_any_groups?(groups)
    end

    def self.request(post)
      return unless eligible?(post)
      post.custom_fields[PENDING_FIELD] = true
      post.save_custom_fields
    end

    def self.enqueue(post)
      return unless enabled? && PostCustomField.exists?(post_id: post.id, name: PENDING_FIELD)
      post.with_lock do
        unless PostCustomField.where(post_id: post.id, name: PENDING_FIELD).delete_all.positive?
          next
        end
        ActiveRecord.after_all_transactions_commit do
          Jobs.enqueue(:isbf_ai_moderation, post_id: post.id)
        end
      end
    end

    def self.content_fingerprint(post)
      Digest::SHA256.hexdigest(
        [
          post.raw,
          post.topic.title,
          post.topic.category_id,
          post.uploads.reorder(:id).pluck(:id),
        ].to_json,
      )
    end

    def self.fingerprint(post)
      Digest::SHA256.hexdigest([content_fingerprint(post), AiConfiguration.fingerprint].to_json)
    end

    def self.approve!(post)
      post.custom_fields[APPROVED_FIELD] = content_fingerprint(post)
      post.save_custom_fields
    end

    def self.scan(post_id, attempt: 0, expected_fingerprint: nil)
      post = Post.find_by(id: post_id)
      return unless eligible?(post)
      scanned_fingerprint = fingerprint(post)
      return if finished?(post, scanned_fingerprint)
      if expected_fingerprint && expected_fingerprint != scanned_fingerprint
        Jobs.enqueue(:isbf_ai_moderation, post_id: post.id)
        return
      end

      error =
        AiConfiguration.error(
          model_id: SiteSetting.isbf_ai_moderation_model,
          images_enabled: SiteSetting.isbf_ai_moderation_images_enabled,
        )
      raise AiClassifier::InvalidResponse, "Moderation configuration: #{error}" if error
      model = AiConfiguration.model
      image_ids =
        if SiteSetting.isbf_ai_moderation_images_enabled
          post
            .uploads
            .order(:id)
            .select { |upload| FileHelper.is_supported_image?("image.#{upload.extension}") }
            .map(&:id)
        else
          []
        end
      RateLimiter.new(
        Discourse.system_user,
        "isbf_ai_moderation",
        MAX_SCANS_PER_MINUTE,
        1.minute,
      ).performed!
      result = AiClassifier.classify(post, model: model, image_ids: image_ids)

      Notifications.defer(post: post) do
        post.with_lock do
          post.reload
          next unless eligible?(post) && !finished?(post, scanned_fingerprint)
          if fingerprint(post) != scanned_fingerprint
            ActiveRecord.after_all_transactions_commit do
              Jobs.enqueue(:isbf_ai_moderation, post_id: post.id)
            end
            next
          end
          if result["needs_review"]
            AiReview.apply!(post, result, fingerprint: scanned_fingerprint, model_id: model.id)
          end
          save_state!(post, scanned_fingerprint, "completed")
        end
      end
    rescue RateLimiter::LimitExceeded
      Jobs.enqueue_in(
        1.minute,
        :isbf_ai_moderation,
        post_id: post_id,
        attempt: attempt,
        fingerprint: scanned_fingerprint,
      )
    rescue StandardError => error
      retry_scan(post_id, scanned_fingerprint, attempt, error)
    end

    def self.finished?(post, scanned_fingerprint)
      return true if post.custom_fields[APPROVED_FIELD] == content_fingerprint(post)
      state = JSON.parse(post.custom_fields[STATE_FIELD].presence || "{}")
      state["fingerprint"] == scanned_fingerprint && %w[completed failed].include?(state["status"])
    end

    def self.save_state!(post, scanned_fingerprint, status)
      post.custom_fields[STATE_FIELD] = {
        fingerprint: scanned_fingerprint,
        status: status,
        updated_at: Time.current.utc.iso8601(6),
      }.to_json
      post.save_custom_fields
    end

    def self.retry_scan(post_id, scanned_fingerprint, attempt, error)
      post = Post.find_by(id: post_id)
      return unless post && scanned_fingerprint
      post.with_lock do
        next unless eligible?(post) && !finished?(post, scanned_fingerprint)
        if fingerprint(post) != scanned_fingerprint
          ActiveRecord.after_all_transactions_commit do
            Jobs.enqueue(:isbf_ai_moderation, post_id: post.id)
          end
          next
        end
        delay = RETRY_DELAYS[attempt]
        save_state!(post, scanned_fingerprint, delay ? "retrying" : "failed")
        if delay
          ActiveRecord.after_all_transactions_commit do
            Jobs.enqueue_in(
              delay,
              :isbf_ai_moderation,
              post_id: post.id,
              attempt: attempt + 1,
              fingerprint: scanned_fingerprint,
            )
          end
        end
      end
      Rails.logger.warn(
        "AI moderation failed for post #{post_id}, attempt #{attempt}: #{error.class.name}",
      )
    end
  end
end
