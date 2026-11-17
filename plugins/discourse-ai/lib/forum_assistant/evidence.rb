# frozen_string_literal: true

module DiscourseAi
  module ForumAssistant
    class Evidence
      SEARCH_CONTEXT_TERMS = %w[
        forum
        forums
        workbench
        post
        posts
        thread
        threads
        discussion
        discussions
        original
        link
        links
        论坛
        工作台
        帖子
        讨论
        原帖
        原帖链接
        链接
        获取
        查看
        查找
        位置
        where
        find
        about
      ].freeze

      attr_reader :sources

      def initialize(user:, decision:)
        @user = user
        @guardian = user.guardian
        @decision = decision
        @query = decision.query.gsub(/[^\p{L}\p{N}\s_-]/u, " ").squish.first(200)
        @sources = []
      end

      def retrieve
        return self if @query.blank?
        add_assistant_help if @decision.intent == "help"
        add_guides if @decision.intent == "help"
        add_posts
        trim_sources
        self
      end

      def references
        sources.map { |source| source.slice(:kind, :id) }
      end

      private

      def add_assistant_help
        return unless @query.match?(/\bai\b|assistant|quota|cooldown|助手|额度|冷却/i)
        @sources << {
          kind: "assistant_help",
          id: 0,
          title: I18n.t("discourse_ai.forum_assistant.help_title"),
          url: "/discourse-ai/ai-bot/conversations",
          authority: "official",
          content:
            I18n.t(
              "discourse_ai.forum_assistant.help_text",
              daily: SiteSetting.ai_forum_assistant_daily_limit,
              minute: SiteSetting.ai_forum_assistant_questions_per_minute,
              timezone: SiteSetting.ai_forum_assistant_timezone,
              cooldown: SiteSetting.ai_forum_assistant_cooldown_minutes,
            ),
        }
      end

      def add_guides
        return unless defined?(::IsbfGuides::Guide) && SiteSetting.isbf_guides_enabled
        terms = searchable_terms
        return if terms.empty?
        scope =
          ::IsbfGuides::Guide.published.joins(:published_revision).includes(:published_revision)
        terms
          .first(6)
          .each do |term|
            scope =
              scope.where(
                "(isbf_guides_revisions.title || ' ' || isbf_guides_revisions.summary || ' ' || isbf_guides_revisions.cooked) ILIKE ?",
                "%#{::IsbfGuides::Guide.sanitize_sql_like(term)}%",
              )
          end
        scope
          .order("isbf_guides_revisions.published_at DESC")
          .limit(Configuration::MAX_SOURCE_COUNT)
          .each do |guide|
            revision = guide.published_revision
            @sources << {
              kind: "guide",
              id: guide.id,
              title: revision.title,
              url: guide.url,
              authority: "official",
              content: Nokogiri::HTML5.fragment(revision.cooked).text.squish,
              updated_at: revision.published_at,
            }
          end
      end

      def add_posts
        count = @sources.length
        add_search_results(@query)
        if @sources.length == count
          searchable_terms
            .sort_by { |term| -term.length }
            .first(Configuration::MAX_FALLBACK_SEARCHES)
            .each do |term|
              next if term == @query
              add_search_results(term)
              break if @sources.length >= Configuration::MAX_SOURCE_COUNT
            end
        end
      end

      def searchable_terms
        terms = @query.split.uniq.reject { |term| SEARCH_CONTEXT_TERMS.include?(term.downcase) }
        terms
      end

      def add_search_results(query)
        result = ::Search.new(query, guardian: @guardian, search_type: :full_page).execute
        return if !result || result.error
        result
          .posts
          .first(30)
          .each do |post|
            next unless visible_post?(post)
            resource = resource_for(post.topic)
            if resource
              @sources << resource
            elsif @decision.intent != "resources"
              @sources << {
                kind: "post",
                id: post.id,
                title: post.topic.title,
                url: post.relative_url,
                authority: "community",
                content: Nokogiri::HTML5.fragment(post.cooked).text.squish,
                updated_at: post.updated_at,
              }
            end
          end
      end

      def visible_post?(post)
        post.topic.archetype == Archetype.default && post.topic.visible && !post.topic.deleted_at &&
          post.post_type == Post.types[:regular] && !post.hidden? && !post.user_deleted &&
          !post.deleted_at && @guardian.can_see_post?(post) &&
          !(defined?(::IsbfModeration::Hold) && ::IsbfModeration::Hold.persisted?(post))
      end

      def resource_for(topic)
        library =
          if defined?(::IsbfLibrary) && ::IsbfLibrary.learning_topic?(topic)
            ::IsbfLibrary
          elsif defined?(::IsbfLearning) && ::IsbfLearning.learning_topic?(topic)
            ::IsbfLearning
          end
        return unless library&.enabled?
        resource = library.resource(topic, @guardian)
        return unless resource
        metadata =
          resource.slice(:title, :description, :grade, :course, :category, :group, :files, :links)
        {
          kind: "resource",
          id: topic.id,
          title: resource[:title],
          url: resource[:url],
          content: metadata.to_json,
          updated_at: topic.updated_at,
        }
      end

      def trim_sources
        @sources =
          sources
            .uniq { |source| [source[:kind], source[:id]] }
            .first(Configuration::MAX_SOURCE_COUNT)
        remaining = Configuration::MAX_SOURCE_CHARACTERS
        @sources.each do |source|
          source[:content] = source[:content].first([remaining, 3000].min)
          remaining -= source[:content].length
        end
        @sources.reject! { |source| source[:content].blank? }
      end
    end
  end
end
