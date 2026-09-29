# frozen_string_literal: true

module IsbfAnonymous
  class PostsController < ::ApplicationController
    requires_plugin IsbfAnonymous::PLUGIN_NAME
    before_action :ensure_logged_in

    PAGE_SIZE = 20

    def index
      before_id = Integer(params[:before_id], exception: false) if params[
        :before_id
      ].present?
      if params[:before_id].present? && !before_id&.positive?
        raise Discourse::InvalidParameters.new(:before_id)
      end

      shadow_ids =
        AnonymousUser.where(master_user_id: current_user.id).select(:user_id)
      posts =
        Post
          .joins(:topic)
          .joins(
            "INNER JOIN post_custom_fields anon_field ON anon_field.post_id = posts.id AND anon_field.name = '#{IsbfAnonymous::POST_FIELD}'"
          )
          .where(
            user_id: shadow_ids,
            deleted_at: nil,
            topics: {
              deleted_at: nil
            }
          )
          .where("anon_field.value = 't'")
      posts = posts.where("posts.id < ?", before_id) if before_id
      rows = posts.order(id: :desc).limit(PAGE_SIZE + 1).includes(:topic).to_a
      has_more = rows.length > PAGE_SIZE
      visible = rows.first(PAGE_SIZE).select { |post| guardian.can_see?(post) }

      render json: {
               posts:
                 visible.map do |post|
                   {
                     id: post.id,
                     title: post.topic.title,
                     excerpt: post.raw.to_s.truncate(180),
                     url: post.url,
                     created_at: post.created_at
                   }
                 end,
               next_before_id: has_more ? rows[PAGE_SIZE - 1].id : nil
             }
    end
  end
end
