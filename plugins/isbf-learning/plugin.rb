# frozen_string_literal: true

# name: isbf-learning
# about: Authenticated course resources and an independent resource library.
# version: 0.6.0
# authors: ISBF Lab
# url: https://github.com/ISBF-Lab/ISBF-Learning
# required_version: 3.2.0

enabled_site_setting :isbf_learning_enabled

after_initialize do
  require_relative "lib/isbf_learning"
  require_relative "lib/isbf_library"
  require_relative "lib/isbf_learning/controllers"
  require_relative "lib/isbf_learning/course_resources"
  require_relative "lib/isbf_library/controllers"
  require_relative "lib/isbf_learning/admin_review"
  require_relative "app/models/reviewable_isbf_learning_course"
  require_relative "app/serializers/reviewable_isbf_learning_course_serializer"
  require_relative "app/models/reviewable_isbf_library_directory"
  require_relative "app/serializers/reviewable_isbf_library_directory_serializer"
  register_reviewable_type ReviewableIsbfLearningCourse
  register_reviewable_type ReviewableIsbfLibraryDirectory

  IsbfLearning.resource_libraries.each do |library|
    {
      library::GROUP_FIELD => :string,
      library::FILES_FIELD => :json,
      library::LINK_FIELD => :string,
      library::DESCRIPTION_FIELD => :string,
      library::CONTRIBUTOR_FIELD => :string,
    }.each do |field, type|
      register_topic_custom_field_type(field, type, max_length: 4096)
      add_permitted_post_create_param(field.to_sym, :string)
      NewPostManager.add_plugin_payload_attribute(field.to_sym)
      # Topic fields use the revision tracker; the native post hook still requires a callable.
      add_permitted_post_update_param(field.to_sym) { |_post, _value| }
      PostRevisor.track_topic_field(field.to_sym) do |changes, value|
        next if value.nil?
        unless library.can_manage?(changes.guardian) &&
                 IsbfLearning.resource_library_for_topic(changes.topic) == library
          raise Discourse::InvalidAccess
        end
        normalized = field == library::FILES_FIELD ? library.file_ids(value) : value.to_s
        normalized = IsbfLearning.external_link(normalized) if field == library::LINK_FIELD
        normalized = IsbfLearning.description(value) if field == library::DESCRIPTION_FIELD
        normalized = IsbfLearning.contributor(value, changes.topic.first_post.user) if field ==
          library::CONTRIBUTOR_FIELD
        if field == library::GROUP_FIELD
          group =
            (
              if library == IsbfLearning
                IsbfLearning::Courses.find(normalized)
              else
                IsbfLibrary::Catalog.find_group(normalized)
              end
            )
          raise Discourse::InvalidParameters.new(field) unless group
        end
        changes.record_change(field, changes.topic.custom_fields[field], normalized)
        changes.topic.custom_fields[field] = normalized
      end
      %i[topic_view post].each do |serializer|
        add_to_serializer(
          serializer,
          field.to_sym,
          include_condition: -> { scope.user.present? },
        ) do
          topic = object.respond_to?(:topic) ? object.topic : object
          topic.custom_fields[field] if IsbfLearning.resource_library_for_topic(topic) == library
        end
      end
    end
  end

  module ::IsbfLearning::ResourceGuardian
    def can_create_topic_on_category?(category)
      id = category.is_a?(Category) ? category.id : category
      library = IsbfLearning.resource_library_for_category(id)
      return super unless library
      library.enabled? && user&.active? && (user.staff? || user.approved?) && !user.silenced? &&
        !user.suspended? &&
        (library.can_manage?(self) || Category.topic_create_allowed(self).exists?(id: id))
    end

    def can_see_topic?(topic, hide_deleted = true)
      return false if IsbfLearning.resource_library_for_topic(topic) && !user
      super
    end

    def can_move_topic_to_category?(category)
      id = category.is_a?(Category) ? category.id : category
      library = IsbfLearning.resource_library_for_category(id)
      return false if library && !library.can_manage?(self)
      super
    end

    def can_delete_topic?(topic)
      library = IsbfLearning.resource_library_for_topic(topic)
      return false if library && !library.can_manage?(self)
      super
    end

    def can_recover_topic?(topic)
      library = IsbfLearning.resource_library_for_topic(topic)
      return false if library && !library.can_manage?(self)
      super
    end

    def can_recover_post?(post)
      topic = post&.topic || (post && Topic.with_deleted.find_by(id: post.topic_id))
      library = IsbfLearning.resource_library_for_topic(topic)
      return false if post&.is_first_post? && library && !library.can_manage?(self)
      super
    end

    def can_edit_post?(post)
      library = IsbfLearning.resource_library_for_topic(post&.topic)
      return false if post&.is_first_post? && library && !library.can_manage?(self)
      super
    end

    def can_edit_topic?(topic)
      library = IsbfLearning.resource_library_for_topic(topic)
      return false if library && !library.can_manage?(self)
      super
    end
  end
  Guardian.prepend(IsbfLearning::ResourceGuardian)

  on(:before_upload_creation) do |_file, image, upload, _validate|
    id = File.basename(upload.original_filename.to_s, File.extname(upload.original_filename.to_s))
    if image && IsbfLearning::Files.valid_id?(id) && IsbfLearning::Files.metadata(id)
      upload.errors.add(:base, I18n.t("isbf_learning.invalid"))
    end
  end

  module ::IsbfLearning::ResourceRevisor
    def revise!(editor, fields, opts = {}, &block)
      library = IsbfLearning.resource_library_for_topic(@post.topic)
      if library && @post.is_first_post?
        raise Discourse::InvalidAccess unless library.can_manage?(editor.guardian)
        IsbfLearning.ensure_scope_fields!(library, fields)
        payload = {
          title: fields[:title] || @post.topic.title,
          raw: fields[:raw] || @post.raw,
          category: fields[:category_id] || @post.topic.category_id,
        }
        library::RESOURCE_FIELDS.each do |field|
          payload[field.to_sym] = fields[field.to_sym] || @post.topic.custom_fields[field]
        end
        unless payload[:category].to_i == library.category_id
          raise Discourse::InvalidParameters.new("category_id")
        end
        library.validate_payload!(editor, payload)
      elsif fields.any? do |key, value|
            IsbfLearning.all_resource_fields.include?(key.to_s) && !value.nil?
          end
        raise Discourse::InvalidParameters.new("resource_library")
      end
      fields =
        fields.reject do |key, value|
          value.nil? && IsbfLearning.all_resource_fields.include?(key.to_s)
        end
      PluginStoreRow.transaction do
        result = super(editor, fields, opts, &block)
        if result && library == IsbfLearning && @post.is_first_post?
          IsbfLearning
            .file_ids(@post.topic.custom_fields[IsbfLearning::FILES_FIELD] || [])
            .each { |id| IsbfLearning::Files.mark_bound!(id) }
        end
        result
      end
    end
  end
  PostRevisor.prepend(IsbfLearning::ResourceRevisor)
  PostRevisor.prepend(IsbfLearning::CourseResourceRevision)
  PostCreator.prepend(IsbfLearning::CourseResourceCreation)
  NewPostManager.prepend(IsbfLearning::CourseResourceSubmission)
  ReviewableQueuedPost.prepend(IsbfLearning::CourseResourceReview)

  NewPostManager.add_handler(-100) do |manager|
    library = IsbfLearning.resource_library_for_category(manager.args[:category])
    supplied = IsbfLearning.all_resource_fields.any? { |field| manager.args[field.to_sym].present? }
    resource = library && manager.args[:topic_id].blank?
    next unless supplied || resource
    begin
      raise Discourse::InvalidParameters.new("resource_library") unless resource
      library.validate_payload!(manager.user, manager.args)
      unless library.can_manage?(manager.user.guardian)
        post = Post.new(raw: manager.args[:raw], user: manager.user, post_number: 1)
        PostValidator.new(skip_topic: true).validate(post)
        if post.errors.present?
          result = NewPostResult.new(:created_post, false)
          result.errors.add(:base, post.errors.full_messages)
          next result
        end
        manager.enqueue(:category)
      end
    rescue Discourse::InvalidParameters, Discourse::InvalidAccess
      result = NewPostResult.new(:create_post, false)
      result.errors.add(
        :base,
        I18n.t(library == IsbfLibrary ? "isbf_library.invalid" : "isbf_learning.invalid"),
      )
      result
    end
  end

  on(:before_create_post) do |post, options|
    next if post.user&.is_system_user?
    library = IsbfLearning.resource_library_for_category(options[:category])
    supplied = IsbfLearning.all_resource_fields.any? { |field| options[field.to_sym].present? }
    resource = library && options[:topic_id].blank?
    next unless supplied || resource
    raise Discourse::InvalidParameters.new("resource_library") unless resource
    library.validate_payload!(post.user, options)
  end

  on(:before_create_topic) do |topic, creator|
    next if creator.user.is_system_user?
    library = IsbfLearning.resource_library_for_topic(topic)
    supplied = IsbfLearning.all_resource_fields.any? { |field| creator.opts[field.to_sym].present? }
    next unless supplied || library
    raise Discourse::InvalidParameters.new("resource_library") unless library
    can_create =
      library.can_manage?(creator.user.guardian) ||
        (creator.opts[:reviewed_queued_post] && library.can_review?(creator.guardian))
    raise Discourse::InvalidAccess unless can_create
    group, files = library.validate_payload!(creator.user, creator.opts)
    topic.custom_fields[library::GROUP_FIELD] = group["id"]
    topic.custom_fields[library::FILES_FIELD] = files
    if creator.opts[library::LINK_FIELD.to_sym].present?
      topic.custom_fields[library::LINK_FIELD] = IsbfLearning.external_link(
        creator.opts[library::LINK_FIELD.to_sym],
      )
    end
    topic.custom_fields[library::DESCRIPTION_FIELD] = IsbfLearning.description(
      creator.opts[library::DESCRIPTION_FIELD.to_sym],
    )
    topic.custom_fields[library::CONTRIBUTOR_FIELD] = IsbfLearning.contributor(
      creator.opts[library::CONTRIBUTOR_FIELD.to_sym],
      creator.user,
    )
    files.each { |id| IsbfLearning::Files.mark_bound!(id) } if library == IsbfLearning
  end

  add_to_serializer(:site, :isbf_learning, include_condition: -> { IsbfLearning.enabled? }) do
    {
      category_id: IsbfLearning.category_id,
      grades: IsbfLearning::GRADES,
      link_sharing: true,
      course_requests: true,
      course_admin_management: true,
      resource_description: true,
      resource_contributor: true,
      resource_admin_management: true,
    }
  end
  add_to_serializer(:site, :isbf_library, include_condition: -> { IsbfLibrary.enabled? }) do
    {
      category_id: IsbfLibrary.category_id,
      link_sharing: true,
      catalog_requests: true,
      resource_description: true,
      resource_contributor: true,
      resource_admin_management: true,
    }
  end

  TopicQuery.add_custom_filter(:isbf_learning_community_exclusion) do |topics, _query|
    ids = IsbfLearning.resource_libraries.filter_map(&:category_id)
    ids.empty? ? topics : topics.where.not(topics: { category_id: ids })
  end

  register_search_advanced_filter(/\Aisbf-learning:library\z/) do |posts, _|
    id = IsbfLearning.category_id
    if id
      posts.where(
        post_number: 1,
        topics: {
          category_id: id,
          visible: true,
          archetype: Archetype.default,
        },
      )
    else
      posts.none
    end
  end
  register_search_advanced_filter(/\Aisbf-library:library\z/) do |posts, _|
    id = IsbfLibrary.category_id
    categories = IsbfLibrary::Catalog.categories.map { |entry| entry["id"] }
    groups =
      IsbfLibrary::Catalog
        .groups
        .select { |entry| categories.include?(entry["category_id"]) }
        .map { |entry| entry["id"] }
    if id
      posts
        .where(
          post_number: 1,
          topics: {
            category_id: id,
            visible: true,
            archetype: Archetype.default,
          },
        )
        .joins(topic: :_custom_fields)
        .where(topic_custom_fields: { name: IsbfLibrary::GROUP_FIELD, value: groups })
    else
      posts.none
    end
  end

  IsbfLearning::Engine.routes.draw do
    get "/" => "library#page"
    get "/courses" => "library#courses"
    post "/courses" => "library#create_course"
    put "/courses/:id" => "library#update_course"
    delete "/courses/:id" => "library#destroy_course"
    get "/resources" => "library#resources"
    post "/resources" => "library#create_resource"
    delete "/resources/:id" => "library#destroy_resource"
    post "/uploads" => "library#upload"
    get "/files/:id" => "library#download"
  end
  IsbfLibrary::Engine.routes.draw do
    get "/" => "library#page"
    get "/categories" => "library#categories"
    post "/categories" => "library#create_category"
    get "/groups" => "library#groups"
    post "/groups" => "library#create_group"
    get "/resources" => "library#resources"
    post "/resources" => "library#create_resource"
    delete "/resources/:id" => "library#destroy_resource"
  end
  Discourse::Application.routes.append do
    mount ::IsbfLearning::Engine, at: "/isbf/learning"
    mount ::IsbfLibrary::Engine, at: "/isbf/library"
  end
end
