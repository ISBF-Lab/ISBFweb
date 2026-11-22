# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    class ResourceEvidence
      CANDIDATE_LIMIT = 24
      DIRECTORY_PREVIEW_LIMIT = 16
      RESOURCE_PREVIEW_LIMIT = 3
      Catalog = Data.define(:key, :library, :category_id, :url, :search_filter)

      def initialize(guardian:, locale:)
        @guardian = guardian
        @locale = ReplyLanguage.translation_locale(locale)
      end

      def search(queries:, scope:)
        batches = visible_catalogs(scope).map { |catalog| search_catalog(catalog, queries) }
        Configuration::MAX_SOURCE_COUNT
          .times
          .flat_map { |index| batches.filter_map { |batch| batch[index] } }
          .first(Configuration::MAX_SOURCE_COUNT)
      end

      def overview(scope)
        visible_catalogs(scope).flat_map do |catalog|
          directories = directories_for(catalog)
          entry =
            catalog_entry(catalog).merge(
              kind: "resource_catalog",
              id: catalog.category_id,
              content:
                directories
                  .values
                  .map { |names| names.join(" · ") }
                  .uniq
                  .first(DIRECTORY_PREVIEW_LIMIT)
                  .join("\n"),
            )
          examples =
            resource_scope(catalog, directories)
              .by_newest
              .limit(CANDIDATE_LIMIT)
              .filter_map { |topic| source(catalog, topic, directories) }
              .first(RESOURCE_PREVIEW_LIMIT)
          [entry, *examples]
        end
      end

      def entries(scope)
        visible_catalogs(scope).map { |catalog| catalog_entry(catalog) }
      end

      def directory_named?(subject)
        name = subject.unicode_normalize(:nfkc).downcase
        visible_catalogs("both").any? do |catalog|
          directories_for(catalog).values.any? do |names|
            names.any? { |entry| entry.unicode_normalize(:nfkc).downcase == name }
          end
        end
      end

      def catalog_for(topic)
        catalogs.find { |catalog| catalog.category_id == topic.category_id }
      end

      def for_topic(catalog, topic)
        return if visible_catalogs("both").exclude?(catalog)
        source(catalog, topic, directories_for(catalog))
      end

      private

      def catalogs
        @catalogs ||=
          if defined?(::IsbfLearning) && defined?(::IsbfLibrary)
            [
              Catalog.new(
                "courses",
                ::IsbfLearning,
                ::IsbfLearning.category_id,
                "/isbf/learning",
                "isbf-learning:library",
              ),
              Catalog.new(
                "library",
                ::IsbfLibrary,
                ::IsbfLibrary.category_id,
                "/isbf/library",
                "isbf-library:library",
              ),
            ].select(&:category_id)
          else
            []
          end
      end

      def visible_catalogs(scope)
        @visible_catalogs ||=
          catalogs.select do |catalog|
            category = Category.find_by(id: catalog.category_id)
            catalog.library.enabled? && category && @guardian.can_see_category?(category) &&
              @guardian.user
          end
        if scope == "both"
          @visible_catalogs
        else
          @visible_catalogs.select { |catalog| catalog.key == scope }
        end
      end

      def catalog_entry(catalog)
        {
          title: I18n.t("discourse_ai.forum_assistant.sources.#{catalog.key}", locale: @locale),
          url: catalog.url,
        }
      end

      def directories_for(catalog)
        @directories ||= {}
        @directories[catalog.key] ||= if catalog.key == "courses"
          grades =
            if ::IsbfLearning::Courses.respond_to?(:grades)
              ::IsbfLearning::Courses.grades
            else
              ::IsbfLearning::GRADES
            end
          grade_names = grades.to_h { |grade| [grade[:id].to_s, grade[:label]] }
          ::IsbfLearning::Courses.list.to_h do |course|
            [course["id"], [grade_names[course["grade"].to_s], course["name"]].compact]
          end
        else
          category_names =
            ::IsbfLibrary::Catalog.categories.to_h { |category| [category["id"], category["name"]] }
          ::IsbfLibrary::Catalog
            .groups
            .filter_map do |group|
              category = category_names[group["category_id"]]
              [group["id"], [category, group["name"]]] if category
            end
            .to_h
        end
      end

      def resource_scope(catalog, directories)
        Topic
          .visible
          .secured(@guardian)
          .where(category_id: catalog.category_id, archetype: Archetype.default, deleted_at: nil)
          .joins(:first_post, :_custom_fields)
          .where(
            topic_custom_fields: {
              name: catalog.library::GROUP_FIELD,
              value: directories.keys,
            },
          )
          .where(
            posts: {
              hidden: false,
              user_deleted: false,
              deleted_at: nil,
              post_type: Post.types[:regular],
            },
          )
      end

      def search_catalog(catalog, queries)
        directories = directories_for(catalog)
        return [] if directories.empty?

        topics = resource_scope(catalog, directories)
        matches = {}
        queries.each do |query|
          candidates =
            metadata_matches(catalog, topics, directories, query)
              .by_newest
              .limit(CANDIDATE_LIMIT)
              .to_a
          native_ids = native_topic_ids(catalog, query)
          candidates.concat(topics.where(id: native_ids).by_newest.to_a) if native_ids.present?
          candidates
            .uniq(&:id)
            .each do |topic|
              next if matches.key?(topic.id)
              entry = source(catalog, topic, directories)
              matches[topic.id] = entry if entry
              break if matches.size >= Configuration::MAX_SOURCE_COUNT
            end
          break if matches.present?
        end
        matches.values
      end

      def native_topic_ids(catalog, query)
        return [] if query.blank?
        search =
          ::Search.new(
            "#{query} #{catalog.search_filter} in:first",
            guardian: @guardian,
            search_type: :full_page,
            type_filter: "topic",
            min_search_term_length: (1 if query.match?(/\A\p{Han}{2,}\z/)),
          )
        result = search.execute(readonly_mode: true)
        return [] if !result || result.error || search.term.blank?
        result.posts.first(CANDIDATE_LIMIT).map(&:topic_id).uniq
      end

      def metadata_matches(catalog, topics, directories, query)
        matches = ["topics.title ILIKE :pattern", <<~SQL.squish]
            EXISTS (
              SELECT 1 FROM topic_custom_fields AS descriptions
              WHERE descriptions.topic_id = topics.id
                AND descriptions.name = :description_field
                AND descriptions.value ILIKE :pattern
            )
          SQL

        directory_ids =
          directories.filter_map do |id, names|
            if names.any? { |name|
                 name.to_s.unicode_normalize(:nfkc).downcase.include?(query.downcase)
               }
              id
            end
          end
        matches << "topic_custom_fields.value IN (:directory_ids)" if directory_ids.present?
        matches << <<~SQL.squish if catalog.key == "courses"
            EXISTS (
              SELECT 1
              FROM topic_custom_fields AS attachments
              JOIN plugin_store_rows AS files
                ON files.plugin_name = :store
                  AND files.key LIKE 'file:%'
                  AND files.type_name = 'JSON'
                  AND jsonb_exists(attachments.value::jsonb, substring(files.key FROM 6))
              WHERE attachments.topic_id = topics.id
                AND attachments.name = :files_field
                AND files.value::jsonb ->> 'name' ILIKE :pattern
            )
          SQL
        topics.where(
          matches.join(" OR "),
          pattern: "%#{Topic.sanitize_sql_like(query)}%",
          directory_ids: directory_ids,
          description_field: catalog.library::DESCRIPTION_FIELD,
          files_field: catalog.library::FILES_FIELD,
          store: catalog.library::STORE,
        )
      end

      def source(catalog, topic, directories)
        return unless catalog.library.visible_resource?(topic, @guardian)
        names = directories[topic.custom_fields[catalog.library::GROUP_FIELD]]
        return unless names
        resource = catalog.library.resource(topic, @guardian)
        return unless resource

        metadata = resource.slice(:title, :description)
        if catalog.key == "courses"
          metadata[:course] = { name: names.last }
          metadata[:grade] = names.first if names.size > 1
        else
          metadata[:category] = { name: names.first }
          metadata[:group] = { name: names.last }
        end
        metadata[:files] = resource[:files].map { |file| file.slice(:name) }
        {
          kind: "resource",
          id: topic.id,
          title: resource[:title],
          url: resource[:url],
          collection: catalog_entry(catalog)[:title],
          catalog_url: catalog.url,
          content: metadata.to_json,
          updated_at: topic.updated_at,
        }
      end
    end
  end
end
