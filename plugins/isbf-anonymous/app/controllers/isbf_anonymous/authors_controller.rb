# frozen_string_literal: true

module IsbfAnonymous
  class AuthorsController < ::ApplicationController
    requires_plugin IsbfAnonymous::PLUGIN_NAME
    before_action :ensure_admin

    def post_author
      post = Post.with_deleted.find(params[:id])
      guardian.ensure_can_see!(post)
      raise Discourse::NotFound unless post.custom_fields[POST_FIELD]

      render_author(IsbfAnonymous.owner_for(post))
    end

    def queued_post_author
      reviewable = ReviewableQueuedPost.viewable_by(current_user).find(params[:id])
      raise Discourse::NotFound unless IsbfAnonymous.requested?(reviewable.payload)

      render_author(IsbfAnonymous.owner_for_reviewable(reviewable))
    end

    private

    def render_author(author)
      raise Discourse::NotFound unless author

      render_json_dump(author: BasicUserSerializer.new(author, scope: guardian, root: false))
    end
  end
end
