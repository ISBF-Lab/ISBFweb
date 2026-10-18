# frozen_string_literal: true

require "securerandom"

module IsbfLibrary
  module Catalog
    def self.categories
      (PluginStore.get(STORE, "categories") || []).map(&:with_indifferent_access)
    end

    def self.groups(category_id = nil)
      result = (PluginStore.get(STORE, "groups") || []).map(&:with_indifferent_access)
      category_id ? result.select { |entry| entry["category_id"] == category_id.to_s } : result
    end

    def self.find_category(id)
      categories.find { |entry| entry["id"] == id.to_s }
    end

    def self.find_group(id)
      groups.find { |entry| entry["id"] == id.to_s }
    end

    def self.normalize(kind:, name:, category_id: nil)
      kind = kind.to_s
      unless %w[category group].include?(kind) && name.is_a?(String)
        raise Discourse::InvalidParameters.new("kind")
      end
      raise Discourse::InvalidParameters.new("name") if name.match?(/[\x00-\x1f\x7f]/)
      name = name.strip.unicode_normalize(:nfkc)
      unless name.length.between?(1, 80) && !name.match?(/[\x00-\x1f\x7f]/)
        raise Discourse::InvalidParameters.new("name")
      end
      result = { "kind" => kind, "name" => name }
      if kind == "group"
        raise Discourse::InvalidParameters.new("category_id") unless find_category(category_id)
        result["category_id"] = category_id.to_s
      elsif category_id.present?
        raise Discourse::InvalidParameters.new("category_id")
      end
      result
    end

    def self.synchronize(&block)
      DistributedMutex.synchronize("isbf-library-catalog", &block)
    end

    def self.create(user, **attributes)
      ensure_staff!(user)
      synchronize { add(normalize(**attributes)) }
    end

    def self.request(user, **attributes)
      IsbfLibrary.ensure_can_submit!(user, user&.guardian)
      synchronize do
        values = normalize(**attributes)
        if matching(values)
          raise Discourse::InvalidParameters.new(I18n.t("isbf_library.duplicate_directory"))
        end
        pending =
          ReviewableIsbfLibraryDirectory
            .pending
            .where(created_by_id: user.id, category_id: IsbfLibrary.category_id)
            .detect do |reviewable|
              payload = reviewable.payload
              payload["kind"] == values["kind"] &&
                payload["category_id"] == values["category_id"] &&
                payload["name"].to_s.casecmp?(values["name"])
            end
        next pending if pending
        reviewable =
          ReviewableIsbfLibraryDirectory.new(
            created_by: user,
            target_created_by: user,
            category_id: IsbfLibrary.category_id,
            payload: values,
            reviewable_by_moderator: true,
            force_review: true,
            potential_spam: false,
          )
        reviewable.created_new!
        reviewable.save!
        reviewable
      end
    end

    def self.approve_locked(user, **attributes)
      ensure_staff!(user)
      add(normalize(**attributes), reuse_existing: true)
    end

    def self.ensure_staff!(user)
      IsbfLibrary.ensure_can_submit!(user, user&.guardian)
      raise Discourse::InvalidAccess unless user.staff?
    end

    def self.matching(values)
      entries = values["kind"] == "category" ? categories : groups(values["category_id"])
      entries.find { |entry| entry["name"].casecmp?(values["name"]) }
    end

    def self.add(values, reuse_existing: false)
      if existing = matching(values)
        return existing if reuse_existing
        raise Discourse::InvalidParameters.new(I18n.t("isbf_library.duplicate_directory"))
      end
      key = values["kind"] == "category" ? "categories" : "groups"
      entries = key == "categories" ? categories : groups
      raise Discourse::InvalidParameters.new(key) if entries.length >= 1000
      entry = values.except("kind").merge("id" => SecureRandom.uuid)
      raise IsbfLearning::StorageError unless PluginStore.set(STORE, key, entries + [entry])
      entry.with_indifferent_access
    end

    private_class_method :add, :matching, :ensure_staff!
  end
end
