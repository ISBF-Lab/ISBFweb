# frozen_string_literal: true

# name: isbf-anonymous
# about: Per-post anonymous publishing for public campus discussions
# version: 0.1.0
# authors: ISBF Lab
# required_version: 3.4.0

module ::IsbfAnonymous
  PLUGIN_NAME = "isbf-anonymous"
  POST_FIELD = "isbf_per_post_anonymous"
end

after_initialize do
  class ::IsbfAnonymous::Engine < ::Rails::Engine
    engine_name IsbfAnonymous::PLUGIN_NAME
    isolate_namespace IsbfAnonymous
  end

  require_relative "lib/isbf_anonymous/permissions"
  require_relative "app/controllers/isbf_anonymous/posts_controller"
  require_relative "app/controllers/isbf_anonymous/pages_controller"

  register_post_custom_field_type(IsbfAnonymous::POST_FIELD, :boolean)
  TopicView.default_post_custom_fields << IsbfAnonymous::POST_FIELD
  add_permitted_post_create_param(:isbf_anonymous, :string)
  allow_new_queued_post_payload_attribute(:isbf_anonymous)
  allow_new_queued_post_payload_attribute(:draft_key)

  Guardian.prepend(IsbfAnonymous::Permissions)
  UsersController.prepend(IsbfAnonymous::SessionToggle)

  register_modifier(:posts_controller_create_user) do |user, options|
    if IsbfAnonymous.requested?(options)
      IsbfAnonymous.ensure_allowed!(user, options)
      AnonymousShadowCreator.get(user) ||
        raise(
          Discourse::InvalidAccess.new(I18n.t("isbf_anonymous.unavailable"))
        )
    else
      user
    end
  end

  on(:post_created) do |post, options|
    next unless IsbfAnonymous.requested?(options)

    post.custom_fields[IsbfAnonymous::POST_FIELD] = true
    post.save_custom_fields

    if options[:advance_draft] && options[:draft_key].present? &&
         (master = IsbfAnonymous.master_for(post.user_id))
      DraftSequence.next!(master, options[:draft_key])
    end
  end

  on(:queued_post_created) do |reviewable|
    next unless IsbfAnonymous.requested?(reviewable.payload)
    next if reviewable.payload["draft_key"].blank?

    if (master = IsbfAnonymous.master_for(reviewable.target_created_by_id))
      DraftSequence.next!(master, reviewable.payload["draft_key"])
    end
  end

  on(:post_alerter_before_replies) do |post, new_record, notified|
    next unless new_record && !post.topic&.private_message?

    target =
      if post.reply_to_post_number.present?
        Post.find_by(
          topic_id: post.topic_id,
          post_number: post.reply_to_post_number
        )
      else
        post.topic&.first_post
      end
    next if target&.id == post.id
    next unless target&.custom_fields&.dig(IsbfAnonymous::POST_FIELD)

    master = IsbfAnonymous.master_for(target.user_id)
    unless master && master.id != post.user_id && !notified.include?(master)
      next
    end
    next if IsbfAnonymous.master_for(post.user_id)&.id == master.id

    notified.concat(PostAlerter.new.notify_non_pm_users(master, :replied, post))
  end

  on(:reviewable_transitioned_to) do |status, reviewable|
    next unless reviewable.is_a?(ReviewableQueuedPost)
    next unless IsbfAnonymous.requested?(reviewable.payload)

    master = IsbfAnonymous.master_for(reviewable.target_created_by_id)
    next unless master

    if status == :approved && reviewable.target.is_a?(Post)
      post = reviewable.target
      Notification.create!(
        notification_type: Notification.types[:post_approved],
        user_id: master.id,
        data: { post_url: post.url }.to_json,
        topic_id: post.topic_id,
        post_number: post.post_number
      )
    elsif status == :rejected
      SystemMessage.create(master, :isbf_anonymous_post_rejected, {})
    end
  end

  IsbfAnonymous::Engine.routes.draw do
    get "/api/posts" => "posts#index"
    get "/posts" => "pages#respond"
  end
  Discourse::Application.routes.append do
    mount ::IsbfAnonymous::Engine, at: "/isbf-anonymous"
  end
end
