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
        资料
        课程资料
        课程资源
        资料库
        获取
        查看
        查找
        位置
        where
        find
        about
      ].freeze

      attr_reader :sources, :query

      def initialize(user:, decision:)
        @guardian = user.guardian
        @decision = decision
        @query = normalize(decision.query)
        @locale = ReplyLanguage.translation_locale(decision.locale || user.effective_locale)
        @resources = ResourceEvidence.new(guardian: @guardian, locale: @locale)
        @sources = []
      end

      def retrieve
        case @decision.intent
        when "resource_overview"
          @sources = @resources.overview(@decision.resource_scope)
        when "resources"
          @sources = @resources.search(queries: search_queries, scope: @decision.resource_scope)
        else
          if @decision.intent == "help"
            add_assistant_help
            add_guides
          end
          add_posts
          if @sources.empty? && @decision.intent == "forum"
            @sources = @resources.search(queries: search_queries, scope: "both")
          end
        end
        trim_sources
        self
      end

      def references
        sources.map { |source| source.slice(:kind, :id) }
      end

      def resource_entries
        @resources.entries(@decision.resource_scope)
      end

      def resource_question?
        %w[resources resource_overview].include?(@decision.intent)
      end

      private

      def add_assistant_help
        return unless @query.match?(/\bai\b|assistant|quota|cooldown|助手|额度|冷却/i)
        @sources << {
          kind: "assistant_help",
          id: 0,
          title: I18n.t("discourse_ai.forum_assistant.help_title", locale: @locale),
          url: "/discourse-ai/ai-bot/conversations",
          authority: "official",
          content:
            I18n.t(
              "discourse_ai.forum_assistant.help_text",
              locale: @locale,
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
        search_queries.each do |phrase|
          break if @sources.length >= Configuration::MAX_SOURCE_COUNT
          add_search_results(phrase)
        end
      end

      def searchable_terms(phrase = @query)
        phrase.split.uniq.reject { |term| SEARCH_CONTEXT_TERMS.include?(term.downcase) }
      end

      def normalize(phrase)
        phrase.unicode_normalize(:nfkc).gsub(/[^\p{L}\p{M}\p{N}.\s_-]/u, " ").squish.first(200)
      end

      def search_queries
        alternatives = @decision.alternatives.map { |phrase| normalize(phrase) }
        [@query, *alternatives, *searchable_terms.sort_by { |term| -term.length }].map do |phrase|
            searchable_terms(phrase).join(" ")
          end
          .select { |phrase| phrase.match?(/[\p{L}\p{N}]/) }
          .uniq
          .first(1 + Configuration::MAX_FALLBACK_SEARCHES)
      end

      def add_search_results(phrase)
        # The general search minimum can discard Chinese names and nicknames after segmentation.
        result =
          ::Search.new(
            phrase,
            guardian: @guardian,
            search_type: :full_page,
            min_search_term_length: (1 if phrase.match?(/\A\p{Han}{2,}\z/)),
          ).execute(readonly_mode: true)
        return if !result || result.error
        result
          .posts
          .first(30)
          .each do |post|
            next unless visible_post?(post)
            catalog = @resources.catalog_for(post.topic)
            if catalog
              if @sources.any? { |source|
                   source[:kind] == "resource" && source[:id] == post.topic_id
                 }
                next
              end
              resource = @resources.for_topic(catalog, post.topic)
              @sources << resource if resource
            else
              next if @sources.any? { |source| source[:kind] == "post" && source[:id] == post.id }
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
            break if @sources.length >= Configuration::MAX_SOURCE_COUNT
          end
      end

      def visible_post?(post)
        post.topic.archetype == Archetype.default && post.topic.visible && !post.topic.deleted_at &&
          post.post_type == Post.types[:regular] && !post.hidden? && !post.user_deleted &&
          !post.deleted_at && @guardian.can_see_post?(post) &&
          !(defined?(::IsbfModeration::Hold) && ::IsbfModeration::Hold.persisted?(post))
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
        @sources.reject! { |source| source[:content].blank? && source[:kind] != "resource_catalog" }
      end
    end
  end
end
