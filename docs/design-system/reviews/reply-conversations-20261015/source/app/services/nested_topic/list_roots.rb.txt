# frozen_string_literal: true

class NestedTopic::ListRoots
  include Service::Base

  params do
    attribute :sort, :string
    attribute :page, :integer
    attribute :target_post_number, :integer

    validates :sort, presence: true
    validates :page, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :target_post_number, numericality: { greater_than: 1 }, allow_nil: true
  end

  model :loader, :build_loader
  model :preloader, :build_preloader
  model :serializer, :build_serializer
  step :load_roots
  only_if(:initial_page) { step :promote_pinned_roots }
  step :expand_reply_trees
  only_if(:targeted_flat_descendant) { step :reveal_target }
  step :prepare_posts
  step :serialize_roots
  only_if(:initial_page) { step :enrich_with_topic_metadata }
  only_if(:final_page) { step :attach_suggested_and_related }

  private

  def build_loader(topic_view:, guardian:)
    NestedReplies::TreeLoader.new(topic: topic_view.topic, guardian: guardian)
  end

  def build_preloader(topic_view:, guardian:)
    NestedReplies::PostPreloader.new(
      topic_view: topic_view,
      topic: topic_view.topic,
      current_user: guardian.user,
      guardian: guardian,
    )
  end

  def build_serializer(topic_view:, guardian:)
    NestedReplies::PostTreeSerializer.new(
      topic: topic_view.topic,
      topic_view: topic_view,
      guardian: guardian,
    )
  end

  def initial_page(params:)
    params.page == 0 || params.target_post_number.present?
  end

  def targeted_flat_descendant(params:, loader:, navigation:)
    loader.flat_replies? && params.target_post_number.present? &&
      navigation[:root_post_number] != params.target_post_number
  end

  def final_page(has_more_roots:)
    !has_more_roots
  end

  def load_roots(params:, loader:, topic_view:)
    if loader.flat_replies?
      navigation = NestedReplies::Navigation.new(loader)
      context[:navigation] = navigation.metadata(
        post_number: params.target_post_number,
        root_index: params.page * NestedReplies::TreeLoader::ROOTS_PER_PAGE + 1,
      )
      context[:root_page] = (
        if params.target_post_number.present?
          context[:navigation][:root_page]
        else
          params.page
        end
      )
      scope = navigation.roots
      context[:roots] = loader.load_posts_for_tree(
        scope.offset(context[:root_page] * NestedReplies::TreeLoader::ROOTS_PER_PAGE).limit(
          NestedReplies::TreeLoader::ROOTS_PER_PAGE,
        ),
      ).to_a
      context[:has_more_roots] = (context[:root_page] + 1) *
        NestedReplies::TreeLoader::ROOTS_PER_PAGE < context[:navigation][:root_count]
    else
      context[:navigation] = nil
      context[:root_page] = params.page
      pinned_post_ids = topic_view.topic.nested_topic&.pinned_post_ids.presence
      scope = loader.root_posts_scope(params.sort)
      scope = scope.where.not(id: pinned_post_ids) if pinned_post_ids.present?
      roots =
        scope.offset(params.page * NestedReplies::TreeLoader::ROOTS_PER_PAGE).limit(
          NestedReplies::TreeLoader::ROOTS_PER_PAGE,
        )
      context[:roots] = loader.load_posts_for_tree(roots).to_a
      context[:has_more_roots] = context[:roots].size == NestedReplies::TreeLoader::ROOTS_PER_PAGE
    end
  end

  def promote_pinned_roots(loader:, topic_view:, roots:)
    pinned_post_ids = topic_view.topic.nested_topic&.pinned_post_ids.presence
    context[:pinned_post_ids] = pinned_post_ids
    context[:roots] = loader.promote_pinned_roots(
      roots,
      pinned_post_ids,
    ) unless loader.flat_replies?
  end

  def expand_reply_trees(loader:, params:, roots:)
    tree_data =
      loader.batch_preload_tree(
        roots,
        params.sort,
        max_depth: NestedReplies::TreeLoader::PRELOAD_DEPTH,
        starting_depth: 0,
      )
    context[:children_map] = tree_data[:children_map]
    context[:all_posts] = tree_data[:all_posts]
  end

  def reveal_target(loader:, params:, navigation:, children_map:, all_posts:)
    root_number = navigation[:root_post_number]
    posts =
      loader.load_posts_for_tree(
        loader.flat_descendants_scope(
          root_number,
          sort: "old",
          offset: navigation[:child_page] * NestedReplies::TreeLoader::CHILDREN_PER_PAGE,
        ),
      ).to_a
    children_map[root_number] = (children_map.fetch(root_number, []) + posts).uniq(&:id).sort_by(
      &:post_number
    )
    all_posts.concat(posts).uniq!(&:id)
  end

  def prepare_posts(params:, loader:, preloader:, all_posts:)
    posts = params.page == 0 ? [loader.op_post] + all_posts : all_posts.dup

    preloader.prepare(posts)
    counts = loader.tree_counts(posts)
    context[:reply_counts] = counts[:reply_counts]
    context[:descendant_counts] = counts[:descendant_counts]
  end

  def serialize_roots(
    params:,
    roots:,
    has_more_roots:,
    children_map:,
    reply_counts:,
    descendant_counts:,
    serializer:,
    navigation:,
    root_page:
  )
    context[:response] = {
      roots:
        roots.map.with_index do |root, index|
          node = serializer.serialize_tree(root, children_map, reply_counts, descendant_counts)
          if navigation
            node[:root_index] = root_page * NestedReplies::TreeLoader::ROOTS_PER_PAGE + index + 1
            if root.post_number == navigation[:root_post_number] &&
                 params.target_post_number.present? && params.target_post_number != root.post_number
              node[:target_post_number] = params.target_post_number
              node[:children_page] = navigation[:child_page]
            end
          end
          node
        end,
      has_more_roots: has_more_roots,
      page: root_page,
    }
    context[:response][:navigation] = navigation if navigation
  end

  def enrich_with_topic_metadata(
    params:,
    serializer:,
    loader:,
    topic_view:,
    reply_counts:,
    descendant_counts:,
    response:,
    pinned_post_ids:,
    has_more_roots:
  )
    suppress_suggested_and_related_queries(topic_view) if has_more_roots
    response[:topic] = serializer.serialize_topic
    response[:op_post] = serializer.serialize_post(loader.op_post, reply_counts, descendant_counts)
    response[:sort] = params.sort
    response[:effective_sort] = loader.effective_sort(params.sort)
    response[:message_bus_last_id] = topic_view.message_bus_last_id
    response[:pinned_post_ids] = pinned_post_ids if pinned_post_ids.present?
  end

  def attach_suggested_and_related(serializer:, response:)
    response.merge!(serializer.serialize_suggested_and_related)
  end

  # Match flat view behavior: don't run the suggested/related queries
  # when there are more pages of roots coming. The core suggested/related
  # queries honor these include_* flags. The discourse-ai plugin's
  # `related_topics` serializer attribute gates on `object.next_page.nil?`
  # (plugins/discourse-ai/lib/embeddings/entry_point.rb), and also uses
  # `related_topics` in its `TopicView#categories` override to preload
  # category badges on lazy_load_categories sites — so we set @next_page
  # to a non-nil value here, which both short-circuits the AI serializer
  # gate and lets the categories override continue to run unchanged.
  # TopicView's skip_post_loading: true otherwise leaves next_page nil.
  def suppress_suggested_and_related_queries(topic_view)
    topic_view.include_suggested = false
    topic_view.include_related = false
    topic_view.instance_variable_set(:@next_page, topic_view.page + 1)
  end
end
