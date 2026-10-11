# frozen_string_literal: true

# name: isbf-anonymous
# about: Per-post anonymous publishing for public campus discussions
# version: 0.1.0
# authors: ISBF Lab
# required_version: 3.4.0

require_relative "app/validators/isbf_anonymous_pool_size_validator"

register_asset "stylesheets/common/isbf-anonymous.scss"

module ::IsbfAnonymous
  PLUGIN_NAME = "isbf-anonymous"
  POST_FIELD = "isbf_per_post_anonymous"
  OWNER_FIELD = "isbf_anonymous_owner_id"
end

after_initialize do
  class ::IsbfAnonymous::Engine < ::Rails::Engine
    engine_name IsbfAnonymous::PLUGIN_NAME
    isolate_namespace IsbfAnonymous
  end

  require_relative "app/models/isbf_anonymous/pool_account"
  require_relative "app/models/isbf_anonymous/pool_assignment"
  require_relative "lib/isbf_anonymous/permissions"
  require_relative "lib/isbf_anonymous/ownership"
  require_relative "lib/isbf_anonymous/pool_protection"
  require_relative "app/controllers/isbf_anonymous/posts_controller"
  require_relative "app/controllers/isbf_anonymous/pages_controller"
  require_relative "app/controllers/isbf_anonymous/authors_controller"

  register_post_custom_field_type(IsbfAnonymous::POST_FIELD, :boolean)
  register_post_custom_field_type(IsbfAnonymous::OWNER_FIELD, :integer)
  TopicView.default_post_custom_fields << IsbfAnonymous::POST_FIELD
  add_to_serializer :post, IsbfAnonymous::POST_FIELD.to_sym do
    post_custom_fields[IsbfAnonymous::POST_FIELD] == true
  end
  add_permitted_post_create_param(:isbf_anonymous, :string)
  allow_new_queued_post_payload_attribute(:isbf_anonymous)
  allow_new_queued_post_payload_attribute(:draft_key)
  allow_new_queued_post_payload_attribute(IsbfAnonymous::OWNER_FIELD.to_sym)

  add_to_serializer :reviewable_queued_post,
                    IsbfAnonymous::POST_FIELD.to_sym,
                    include_condition: -> do
                      scope&.is_admin? ||
                        (scope.respond_to?(:academy_can?) && scope.academy_can?(:trace_anonymous))
                    end do
    IsbfAnonymous.requested?(object.payload) == true
  end

  Guardian.prepend(IsbfAnonymous::Permissions)
  Guardian.prepend(IsbfAnonymous::PoolPermissions)
  UsersController.prepend(IsbfAnonymous::SessionToggle)
  User.has_one :isbf_anonymous_pool_account,
               class_name: "IsbfAnonymous::PoolAccount",
               dependent: :restrict_with_exception
  User.has_one :isbf_anonymous_pool_assignment,
               class_name: "IsbfAnonymous::PoolAssignment",
               foreign_key: :master_user_id,
               dependent: :destroy
  User.prepend(IsbfAnonymous::PostingUser)
  User.singleton_class.prepend(IsbfAnonymous::RealUsers)
  UserSearch.prepend(IsbfAnonymous::SearchUsers)
  AdminUserIndexQuery.prepend(IsbfAnonymous::AdminUsers)
  DirectoryItem.singleton_class.prepend(IsbfAnonymous::DirectoryUsers)
  Auth::DefaultCurrentUserProvider.prepend(IsbfAnonymous::PoolSessions)
  UserSilencer.prepend(IsbfAnonymous::PoolSilencer)
  NewPostManager.prepend(IsbfAnonymous::PostingCounts)
  PostCreator.prepend(IsbfAnonymous::PostCreation)
  ReviewableQueuedPost.prepend(IsbfAnonymous::QueuedPost)
  UserCardSerializer.prepend(IsbfAnonymous::PendingCounts)

  register_modifier(:posts_controller_pending_posts) do |posts, controller, user|
    if controller.guardian.is_admin? || controller.current_user.id == user.id
      posts
    else
      posts.where("payload->>? IS NULL", IsbfAnonymous::OWNER_FIELD)
    end
  end

  register_modifier(:posts_controller_create_user) do |user, options|
    if IsbfAnonymous.requested?(options)
      IsbfAnonymous.ensure_allowed!(user, options)
      options[:acting_user] = user
      options[IsbfAnonymous::OWNER_FIELD.to_sym] = user.id
      options[:auto_track] = false
      author =
        if SiteSetting.isbf_anonymous_pool_enabled
          IsbfAnonymous::PoolAssignment.author_for!(user)
        else
          AnonymousShadowCreator.get(user)
        end
      author || raise(Discourse::InvalidAccess.new(I18n.t("isbf_anonymous.unavailable")))
    else
      user
    end
  end

  on(:queued_post_created) do |reviewable|
    next unless IsbfAnonymous.requested?(reviewable.payload)
    next if reviewable.payload["draft_key"].blank?

    if (master = IsbfAnonymous.owner_for_reviewable(reviewable))
      DraftSequence.next!(master, reviewable.payload["draft_key"])
    end
  end

  on(:post_alerter_before_replies) do |post, new_record, notified|
    next unless new_record && !post.topic&.private_message?

    target =
      if post.reply_to_post_number.present?
        Post.find_by(topic_id: post.topic_id, post_number: post.reply_to_post_number)
      else
        post.topic&.first_post
      end
    next if target&.id == post.id
    next unless target&.custom_fields&.dig(IsbfAnonymous::POST_FIELD)

    master = IsbfAnonymous.owner_for(target)
    next unless master && master.id != post.user_id && !notified.include?(master)
    if post.custom_fields[IsbfAnonymous::POST_FIELD] &&
         IsbfAnonymous.owner_for(post)&.id == master.id
      next
    end

    notified.concat(PostAlerter.new.notify_non_pm_users(master, :replied, post))
  end

  on(:reviewable_transitioned_to) do |status, reviewable|
    next unless reviewable.is_a?(ReviewableQueuedPost)
    next unless IsbfAnonymous.requested?(reviewable.payload)

    master = IsbfAnonymous.owner_for_reviewable(reviewable)
    next unless master

    SystemMessage.create(master, :isbf_anonymous_post_rejected, {}) if status == :rejected
  end

  IsbfAnonymous::Engine.routes.draw do
    get "/api/posts" => "posts#index"
    get "/posts" => "pages#respond"
    get "/api/posts/:id/author" => "authors#post_author"
    get "/api/queued-posts/:id/author" => "authors#queued_post_author"
  end
  Discourse::Application.routes.append { mount ::IsbfAnonymous::Engine, at: "/isbf-anonymous" }
end
