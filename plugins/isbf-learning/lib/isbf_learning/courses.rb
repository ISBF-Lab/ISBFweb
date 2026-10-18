# frozen_string_literal: true

require "securerandom"

module IsbfLearning
  module Courses
    def self.list(include_deleted: false)
      courses = (PluginStore.get(STORE, "courses") || []).map(&:with_indifferent_access)
      include_deleted ? courses : courses.reject { |course| course["deleted_at"].present? }
    end

    def self.find(id)
      list.find { |course| course["id"] == id.to_s }
    end

    def self.normalize(name:, grade:)
      raise Discourse::InvalidParameters.new("name") unless name.is_a?(String)
      name = name.strip.unicode_normalize(:nfkc)
      raise Discourse::InvalidParameters.new("name") unless name.length.between?(1, 80)
      raise Discourse::InvalidParameters.new("grade") unless grade.to_s.match?(/\A[1-4]\z/)
      { "name" => name, "grade" => grade.to_i }
    end

    # Hold the catalog mutex through the outer review transaction's commit.
    def self.synchronize(&block)
      DistributedMutex.synchronize("isbf-learning-courses") { with_catalog_lock(&block) }
    end

    def self.with_catalog_lock
      PluginStoreRow.transaction do
        scope = PluginStoreRow.where(plugin_name: STORE, key: "courses")
        row =
          scope.first ||
            scope.create_or_find_by!(plugin_name: STORE, key: "courses") do |record|
              record.type_name = "JSON"
              record.value = "[]"
            end
        row.lock!
        yield
      end
    end

    def self.update(user, id, name:, grade:)
      ensure_admin!(user)
      attributes = normalize(name: name, grade: grade)
      with_catalog_lock do
        courses = list(include_deleted: true)
        course = courses.find { |entry| entry["id"] == id.to_s && entry["deleted_at"].blank? }
        raise Discourse::NotFound unless course
        if (duplicate = matching(attributes)) && duplicate["id"] != course["id"]
          raise Discourse::InvalidParameters.new(I18n.t("isbf_learning.duplicate_course"))
        end
        course.merge!(attributes)
        raise StorageError unless PluginStore.set(STORE, "courses", courses)
        course
      end
    end

    def self.destroy(user, id)
      ensure_admin!(user)
      with_catalog_lock do
        courses = list(include_deleted: true)
        course = courses.find { |entry| entry["id"] == id.to_s && entry["deleted_at"].blank? }
        raise Discourse::NotFound unless course
        resource_ids = []
        reviewable_ids = []
        topics =
          Topic
            .where(category_id: IsbfLearning.category_id, archetype: Archetype.default)
            .joins(:_custom_fields)
            .where(topic_custom_fields: { name: COURSE_FIELD, value: course["id"] })
            .distinct
        topics.find_each do |topic|
          user.guardian.ensure_can_delete!(topic)
          post = Post.with_deleted.find_by(topic_id: topic.id, post_number: 1)
          raise StorageError unless post
          PostDestroyer.new(user, post, context: I18n.t("isbf_learning.course_deleted")).destroy
          raise StorageError unless Topic.with_deleted.find(topic.id).deleted_at
          resource_ids << topic.id
        end
        ReviewableQueuedPost
          .pending
          .where(category_id: IsbfLearning.category_id)
          .where("payload ->> ? = ?", COURSE_FIELD, course["id"])
          .find_each do |reviewable|
            raise StorageError unless reviewable.perform(user, :reject_post).success?
            reviewable_ids << reviewable.id
          end
        course.merge!(
          "deleted_at" => Time.now.utc.iso8601(6),
          "deleted_by_id" => user.id,
          "deleted_resource_ids" => resource_ids,
          "rejected_reviewable_ids" => reviewable_ids,
        )
        raise StorageError unless PluginStore.set(STORE, "courses", courses)
      end
    end

    def self.create(user, name:, grade:)
      ensure_staff!(user)
      attributes = normalize(name: name, grade: grade)
      synchronize { add(attributes) }
    end

    def self.request(user, name:, grade:)
      IsbfLearning.ensure_can_submit!(user, user&.guardian)
      attributes = normalize(name: name, grade: grade)
      synchronize do
        if matching(attributes)
          raise Discourse::InvalidParameters.new(I18n.t("isbf_learning.duplicate_course"))
        end
        pending =
          ReviewableIsbfLearningCourse
            .pending
            .where(created_by_id: user.id, category_id: IsbfLearning.category_id)
            .detect do |reviewable|
              stored =
                normalize(
                  name: reviewable.payload["course_name"],
                  grade: reviewable.payload["grade"],
                )
              stored["grade"] == attributes["grade"] && stored["name"].casecmp?(attributes["name"])
            end
        next pending if pending
        reviewable =
          ReviewableIsbfLearningCourse.new(
            created_by: user,
            target_created_by: user,
            category_id: IsbfLearning.category_id,
            payload: {
              "course_name" => attributes["name"],
              "grade" => attributes["grade"],
            },
            reviewable_by_moderator: true,
            force_review: true,
            potential_spam: false,
          )
        reviewable.created_new!
        reviewable.save!
        reviewable
      end
    end

    # Called inside ReviewableIsbfLearningCourse#perform's shared catalog lock.
    def self.approve_locked(user, name:, grade:)
      ensure_staff!(user, review: true)
      add(normalize(name: name, grade: grade), reuse_existing: true)
    end

    def self.ensure_staff!(user, review: false)
      permitted =
        user &&
          (
            if review
              IsbfLearning.can_review?(user.guardian)
            else
              IsbfLearning.can_manage?(user.guardian)
            end
          )
      permitted ||=
        user&.staff? &&
          !(SiteSetting.respond_to?(:academy_roles_enabled?) && SiteSetting.academy_roles_enabled?)
      raise Discourse::InvalidAccess unless permitted && !user.silenced? && !user.suspended?
    end

    def self.matching(attributes)
      list.find do |course|
        course["grade"] == attributes["grade"] && course["name"].casecmp?(attributes["name"])
      end
    end

    def self.add(attributes, reuse_existing: false)
      if existing = matching(attributes)
        return existing if reuse_existing
        raise Discourse::InvalidParameters.new(I18n.t("isbf_learning.duplicate_course"))
      end
      courses = list(include_deleted: true)
      raise Discourse::InvalidParameters.new("courses") if list.length >= 1000
      course = attributes.merge("id" => SecureRandom.uuid)
      raise StorageError unless PluginStore.set(STORE, "courses", courses + [course])
      course.with_indifferent_access
    end

    def self.ensure_admin!(user)
      raise Discourse::InvalidAccess unless user && user.guardian.is_admin?
      IsbfLearning.ensure_can_submit!(user, user&.guardian)
    end

    private_class_method :add, :matching, :ensure_staff!, :ensure_admin!
  end
end
