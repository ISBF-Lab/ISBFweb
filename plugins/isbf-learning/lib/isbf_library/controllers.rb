# frozen_string_literal: true

module IsbfLibrary
  class Engine < ::Rails::Engine
    engine_name "isbf-library"
    isolate_namespace IsbfLibrary
  end

  class LibraryController < ::ApplicationController
    wrap_parameters false
    requires_login
    requires_plugin "isbf-learning"
    before_action :check_category

    def page
      render html: "".html_safe, layout: "application"
    end

    def categories
      render json: { categories: Catalog.categories }
    end

    def groups
      if params[:category_id].present? && !Catalog.find_category(params[:category_id])
        raise Discourse::InvalidParameters.new("category_id")
      end
      render json: { groups: Catalog.groups(params[:category_id].presence) }
    end

    def create_category
      create_directory("category")
    end

    def create_group
      create_directory("group")
    end

    def resources
      page = params[:page].presence || "0"
      raise Discourse::InvalidParameters.new("page") unless page.to_s.match?(/\A\d{1,4}\z/)
      page = page.to_i
      query = params[:q].to_s.strip
      if query.present?
        raise Discourse::InvalidParameters.new("q") if query.length > 200
        RateLimiter.new(current_user, "isbf-library-search", 30, 1.minute).performed!
        results =
          Search.new(
            "#{query} isbf-library:library in:first",
            guardian: guardian,
            search_type: :full_page,
            type_filter: "topic",
            page: page + 1,
            search_context: Category.find(IsbfLibrary.category_id),
          ).execute
        raise Discourse::InvalidParameters.new("q") if results.error
        topics = results.posts.map(&:topic).uniq(&:id)
        more = results.more_full_page_results || results.more_posts
      else
        return render json: { resources: [], has_more: false } if params[:group_id].blank?
        group = Catalog.find_group(params[:group_id])
        unless group && Catalog.find_category(group["category_id"])
          raise Discourse::InvalidParameters.new("group_id")
        end
        limit = 20
        scope =
          Topic
            .visible
            .secured(guardian)
            .where(category_id: IsbfLibrary.category_id, archetype: Archetype.default)
            .joins(:_custom_fields)
            .where(topic_custom_fields: { name: GROUP_FIELD, value: group["id"] })
            .joins(:first_post)
            .where(
              posts: {
                hidden: false,
                user_deleted: false,
                deleted_at: nil,
                post_type: Post.types[:regular],
              },
            )
            .order(created_at: :desc, id: :desc)
        topics = scope.offset(page * limit).limit(limit + 1).to_a
        more = topics.length > limit
        topics = topics.first(limit)
      end
      render json: {
               resources: topics.filter_map { |topic| IsbfLibrary.resource(topic, guardian) },
               has_more: !!more,
             }
    end

    def create_resource
      IsbfLibrary.ensure_can_submit!(current_user, guardian)
      RateLimiter.new(current_user, "isbf-library-share", 10, 1.minute).performed!
      title = params[:title].is_a?(String) ? params[:title].strip : ""
      link = IsbfLearning.external_link(params[:link])
      description = IsbfLearning.description(params[:description])
      contributor = IsbfLearning.contributor(params[:contributor], current_user)
      options = {
        title: title,
        raw: IsbfLearning.link_body(title, link, description),
        category: IsbfLibrary.category_id,
        archetype: Archetype.default,
        isbf_library_group_id: params[:group_id],
        isbf_library_files: "[]",
        isbf_library_link: link,
        isbf_library_description: description,
        isbf_library_contributor: contributor,
      }
      IsbfLibrary.validate_payload!(current_user, options)
      creator = TopicCreator.new(current_user, guardian, options)
      return render_json_error(creator.errors.full_messages, status: 422) unless creator.valid?
      result = NewPostManager.new(current_user, options).perform
      return render_json_error(result.errors.full_messages, status: 422) unless result.success?
      render json: {
               success: true,
               pending: result.reviewable.present? && result.post.nil?,
               resource: result.post && IsbfLibrary.resource(result.post.topic, guardian),
             }
    rescue Discourse::InvalidParameters => error
      render_json_error(error.message, status: 422)
    end

    def destroy_resource
      raise Discourse::InvalidAccess unless guardian.is_admin?
      unless params[:id].to_s.match?(/\A[1-9]\d{0,18}\z/)
        raise Discourse::InvalidParameters.new("id")
      end
      topic = Topic.includes(:first_post).find_by(id: params[:id])
      raise Discourse::NotFound unless topic && IsbfLibrary.resource(topic, guardian)
      guardian.ensure_can_delete!(topic)
      PostDestroyer.new(current_user, topic.first_post).destroy
      unless Topic.with_deleted.find_by(id: topic.id)&.deleted_at
        return render_json_error(I18n.t("isbf_learning.delete_failed"), status: 422)
      end
      render json: { success: true }
    end

    private

    def create_directory(kind)
      IsbfLibrary.ensure_can_submit!(current_user, guardian)
      RateLimiter.new(current_user, "isbf-library-catalog", 10, 1.minute).performed!
      attributes = {
        kind: kind,
        name: params[:name],
        category_id: kind == "group" ? params[:category_id] : nil,
      }
      if current_user.staff?
        entry = Catalog.create(current_user, **attributes)
        render json: { :success => true, :pending => false, kind => entry }
      else
        reviewable = Catalog.request(current_user, **attributes)
        render json: { success: true, pending: true, reviewable_id: reviewable.id }
      end
    rescue Discourse::InvalidParameters => error
      render_json_error(error.message, status: 422)
    rescue IsbfLearning::StorageError
      render_json_error(I18n.t("isbf_library.directory_storage_error"), status: 422)
    end

    def check_category
      category = Category.find_by(id: IsbfLibrary.category_id)
      unless IsbfLibrary.enabled? && category && guardian.can_see_category?(category)
        raise Discourse::InvalidAccess
      end
    end
  end
end
