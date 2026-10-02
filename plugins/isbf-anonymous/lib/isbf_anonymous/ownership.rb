# frozen_string_literal: true

module IsbfAnonymous
  def self.owner_for(post)
    owner_id = PostCustomField.where(post_id: post.id, name: OWNER_FIELD).pick(:value)
    owner_id ? User.find_by(id: owner_id) : master_for(post.user_id)
  end

  def self.owner_for_reviewable(reviewable)
    owner_id = reviewable.payload&.[](OWNER_FIELD)
    owner_id ? User.find_by(id: owner_id) : master_for(reviewable.target_created_by_id)
  end

  def self.owned_post_ids(user_id)
    private_ids =
      PostCustomField
        .where(name: OWNER_FIELD)
        .where("LEFT(value, 200) = ?", user_id.to_s)
        .select(:post_id)
    shadow_ids = AnonymousUser.where(master_user_id: user_id).select(:user_id)
    marked_ids = PostCustomField.where(name: POST_FIELD, value: "t").select(:post_id)
    Post.where(id: private_ids).or(Post.where(user_id: shadow_ids, id: marked_ids)).select(:id)
  end

  module PostingUser
    def anonymous?
      super || IsbfAnonymous.pool_user?(self)
    end

    def posts_for_posting_limits
      Post.where(user_id: id).or(Post.where(id: IsbfAnonymous.owned_post_ids(id)))
    end

    def pending_posts
      super.or(ReviewableQueuedPost.pending.where("payload->>? = ?", OWNER_FIELD, id.to_s))
    end
  end

  module PostingCounts
    def post_count
      return super unless IsbfAnonymous.requested?(args)

      acting_user
        .posts_for_posting_limits
        .joins(:topic)
        .where("post_number > 1")
        .where(post_type: Post.types[:regular], topics: { archetype: Archetype.default })
        .count
    end

    def topic_count
      return super unless IsbfAnonymous.requested?(args)

      acting_user
        .posts_for_posting_limits
        .joins(:topic)
        .where(post_number: 1, topics: { archetype: Archetype.default })
        .count
    end
  end

  module PendingCounts
    def pending_posts_count
      return super if scope.is_admin? || scope.is_me?(object)

      object.pending_posts.where("payload->>? IS NULL", OWNER_FIELD).count
    end
  end

  module PostCreation
    private

    def setup_post
      super
      return unless IsbfAnonymous.requested?(opts)

      @post.custom_fields[POST_FIELD] = true
      @post.custom_fields[OWNER_FIELD] = opts[OWNER_FIELD.to_sym] if opts[OWNER_FIELD.to_sym]
    end
  end

  module QueuedPost
    def create_options
      options = super
      return options unless IsbfAnonymous.requested?(payload)

      owner = IsbfAnonymous.owner_for_reviewable(self)
      raise Discourse::InvalidAccess unless owner

      options.merge(acting_user: owner, auto_track: false)
    end

    def notification_user
      IsbfAnonymous.requested?(payload) ? IsbfAnonymous.owner_for_reviewable(self) : super
    end
  end
end
