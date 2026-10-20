# frozen_string_literal: true

# name: isbf-moderation
# about: Immediate holding and native staff review of serious ISBF community reports.
# version: 0.1.0
# authors: ISBF Lab
# url: https://github.com/ISBF-Lab/ISBF-Moderation
# required_version: 3.5.0

require_relative "lib/isbf_moderation/ai_configuration"

after_initialize do
  require_relative "lib/isbf_moderation/hold"
  require_relative "lib/isbf_moderation/policy"
  require_relative "lib/isbf_moderation/audit"
  require_relative "lib/isbf_moderation/notifications"
  require_relative "lib/isbf_moderation/severe_report"
  require_relative "lib/isbf_moderation/protections"
  require_relative "lib/isbf_moderation/serializers"
  require_relative "lib/isbf_moderation/review_queue"
  require_relative "lib/isbf_moderation/ai_classifier"
  require_relative "lib/isbf_moderation/ai_review"
  require_relative "lib/isbf_moderation/ai_scanner"
  require_relative "app/jobs/regular/isbf_ai_moderation"

  register_post_custom_field_type(IsbfModeration::Hold::FIELD, :integer)
  register_post_custom_field_type(IsbfModeration::AiScanner::PENDING_FIELD, :boolean)
  register_post_custom_field_type(IsbfModeration::AiScanner::STATE_FIELD, :string)
  register_post_custom_field_type(IsbfModeration::AiScanner::APPROVED_FIELD, :string)

  on(:post_created) { |post| IsbfModeration::AiScanner.request(post) }
  on(:post_edited) do |post, topic_changed, revisor|
    if revisor.reviewable_content_changed? || topic_changed
      IsbfModeration::AiScanner.request(post)
      IsbfModeration::AiScanner.enqueue(post) unless revisor.raw_changed?
    end
  end
  on(:post_process_cooked) { |_document, post| IsbfModeration::AiScanner.enqueue(post) }
  register_topic_preloader_associations(:first_post)

  # The setting controls submissions only. Existing holds must survive disabling it.
  reloadable_patch do
    if TopicView.default_post_custom_fields.exclude?(IsbfModeration::Hold::FIELD)
      TopicView.default_post_custom_fields << IsbfModeration::Hold::FIELD
    end
    Guardian.prepend(IsbfModeration::GuardianProtection)
    Post.prepend(IsbfModeration::PostProtection)
    PostRevisor.prepend(IsbfModeration::RevisionProtection)
    PostActionDestroyer.prepend(IsbfModeration::WithdrawalProtection)
    TopicTrackingState.singleton_class.prepend(IsbfModeration::TrackingNotifications)
    TopicUser.singleton_class.prepend(IsbfModeration::TopicUserNotifications)
    Jobs.singleton_class.prepend(IsbfModeration::HoldSystemMessageNotifications)
    ReviewableFlaggedPost.prepend(IsbfModeration::ReviewProtection)
    Reviewable.singleton_class.prepend(IsbfModeration::ReviewQueue)
    BasicPostSerializer.prepend(IsbfModeration::BasicPostProtection)
    PostSerializer.prepend(IsbfModeration::PostSerializerProtection)
    ListableTopicSerializer.prepend(IsbfModeration::TopicSerializerProtection)
    TopicViewSerializer.prepend(IsbfModeration::TopicViewSerializerProtection)
    ReviewableFlaggedPostSerializer.prepend(IsbfModeration::ReviewSerializerProtection)
    ReviewableScoreSerializer.prepend(IsbfModeration::ScoreSerializerProtection)
    UserActionSerializer.prepend(IsbfModeration::UserActionProtection)
    UserAction.singleton_class.prepend(IsbfModeration::ActivityHoldPreloader)
  end

  add_custom_reviewable_filter(
    [:isbf_severe_priority, ->(relation, _) { IsbfModeration::ReviewQueue.prioritize(relation) }],
  )

  add_to_serializer(:site, :isbf_severe_reports_enabled) { SiteSetting.isbf_severe_reports_enabled }
  add_to_serializer(:post, :isbf_can_severe_report) do
    IsbfModeration::Policy.can_report?(scope.user, object, guardian: scope)
  end
  add_to_serializer(:post, :isbf_severe_report_pending) { IsbfModeration::Hold.active?(object) }
  add_to_serializer(:topic_list_item, :isbf_can_severe_report) do
    IsbfModeration::Policy.can_report?(scope.user, object.first_post, guardian: scope)
  end

  module ::IsbfModeration
    class Engine < ::Rails::Engine
      engine_name "isbf-moderation"
      isolate_namespace IsbfModeration
    end
  end

  class ::IsbfModeration::SevereReportsController < ::ApplicationController
    wrap_parameters false
    requires_login
    requires_plugin "isbf-moderation"

    def create
      allowed = %w[post_id reason confirmed controller action format]
      unknown = params.keys - allowed
      raise Discourse::InvalidParameters.new(unknown.first) if unknown.present?

      render json:
               IsbfModeration::SevereReport.new(current_user, guardian).submit(
                 post_id: params[:post_id],
                 reason: params[:reason],
                 confirmed: params[:confirmed],
               )
    end
  end

  IsbfModeration::Engine.routes.draw { post "/severe-reports" => "severe_reports#create" }
  Discourse::Application.routes.append { mount ::IsbfModeration::Engine, at: "/isbf/moderation" }
end
