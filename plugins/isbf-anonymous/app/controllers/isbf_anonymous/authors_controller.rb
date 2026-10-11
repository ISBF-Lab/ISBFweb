# frozen_string_literal: true

module IsbfAnonymous
  class AuthorsController < ::ApplicationController
    requires_plugin IsbfAnonymous::PLUGIN_NAME
    requires_login
    before_action :ensure_author_lookup_permission

    def post_author
      post = Post.with_deleted.find(params[:id])
      guardian.ensure_can_see!(post)
      if post.user_deleted? && guardian.respond_to?(:academy_restricted_moderator?) &&
           guardian.academy_restricted_moderator? && !guardian.academy_can?(:hidden_content)
        raise Discourse::InvalidAccess
      end
      raise Discourse::NotFound unless post.custom_fields[POST_FIELD]

      render_author(IsbfAnonymous.owner_for(post))
    end

    def queued_post_author
      reviewable = ReviewableQueuedPost.viewable_by(current_user).find(params[:id])
      raise Discourse::NotFound unless IsbfAnonymous.requested?(reviewable.payload)

      render_author(IsbfAnonymous.owner_for_reviewable(reviewable))
    end

    private

    def ensure_author_lookup_permission
      permitted =
        (
          if guardian.respond_to?(:academy_can?)
            guardian.academy_can?(:trace_anonymous)
          else
            guardian.is_admin?
          end
        )
      raise Discourse::InvalidAccess unless permitted
    end

    def render_author(author)
      raise Discourse::NotFound unless author

      render_json_dump(author: BasicUserSerializer.new(author, scope: guardian, root: false))
    end
  end
end
