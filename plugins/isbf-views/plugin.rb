# frozen_string_literal: true

# name: isbf-views
# about: Counts each signed-in viewer once across feed impressions and topic visits.
# version: 0.1.0
# authors: ISBF Lab
# url: https://github.com/ISBF-Lab/ISBF-Views
# required_version: 3.2.0

enabled_site_setting :isbf_views_enabled

after_initialize do
  module ::IsbfViews
    class Engine < ::Rails::Engine
      engine_name "isbf-views"
      isolate_namespace IsbfViews
    end

    class PostImpression < ::ActiveRecord::Base
      self.table_name = "isbf_post_view_impressions"

      belongs_to :post
      belongs_to :user
    end

    class Impression < ::ActiveRecord::Base
      self.table_name = "isbf_view_impressions"

      belongs_to :topic
      belongs_to :user
    end
  end

  class ::IsbfViews::ImpressionsController < ::ApplicationController
    MAX_TOPICS = 50

    requires_login

    def create
      raise Discourse::NotFound unless SiteSetting.isbf_views_enabled

      raw_ids = params[:topic_ids]
      unless raw_ids.is_a?(Array) && raw_ids.length.between?(1, MAX_TOPICS)
        raise Discourse::InvalidParameters.new(:topic_ids)
      end

      ids = raw_ids.map { |id| Integer(id, exception: false) }
      raise Discourse::InvalidParameters.new(:topic_ids) if ids.any? { |id| !id || id <= 0 }
      ids.uniq!

      visible_ids =
        Topic
          .listable_topics
          .secured(guardian)
          .where(id: ids, archetype: Archetype.default)
          .pluck(:id)

      if visible_ids.present?
        now = Time.zone.now
        rows =
          visible_ids.map do |topic_id|
            { topic_id: topic_id, user_id: current_user.id, created_at: now }
          end
        IsbfViews::Impression.insert_all(
          rows,
          unique_by: :index_isbf_view_impressions_on_topic_id_and_user_id,
        )
      end

      counts = {}
      if visible_ids.present?
        DB
          .query(<<~SQL, topic_ids: visible_ids)
            SELECT topic_id, COUNT(*) AS view_count
            FROM (
              SELECT topic_id, user_id
              FROM topic_views
              WHERE topic_id IN (:topic_ids) AND user_id IS NOT NULL
              UNION
              SELECT topic_id, user_id
              FROM isbf_view_impressions
              WHERE topic_id IN (:topic_ids)
            ) AS unique_views
            GROUP BY topic_id
          SQL
          .each { |row| counts[row.topic_id] = row.view_count.to_i }
      end

      render json: { counts: visible_ids.to_h { |id| [id, counts.fetch(id, 0)] } }
    end
  end

  class ::IsbfViews::PostImpressionsController < ::ApplicationController
    MAX_POSTS = 50
    MAX_POST_ID = (2**63) - 1

    requires_login

    def create
      raise Discourse::NotFound unless SiteSetting.isbf_views_enabled

      raw_ids = params[:post_ids]
      unless raw_ids.is_a?(Array) && raw_ids.length.between?(1, MAX_POSTS)
        raise Discourse::InvalidParameters.new(:post_ids)
      end

      ids =
        raw_ids.map do |id|
          if id.is_a?(Integer) || (id.is_a?(String) && id.match?(/\A[1-9][0-9]*\z/))
            Integer(id, exception: false)
          end
        end
      if ids.any? { |id| !id || !id.between?(1, MAX_POST_ID) }
        raise Discourse::InvalidParameters.new(:post_ids)
      end

      topics =
        Topic
          .listable_topics
          .secured(guardian)
          .where(archetype: Archetype.default, visible: true, deleted_at: nil)
      visible_ids =
        Post
          .where(id: ids.uniq, topic_id: topics.select(:id))
          .where(post_type: Post.types[:regular], deleted_at: nil, hidden: false)
          .where("post_number > 1 AND user_id > 0")
          .includes(:topic)
          .select { |post| guardian.can_see_post?(post) }
          .map(&:id)

      counts = {}
      if visible_ids.present?
        now = Time.zone.now
        rows =
          visible_ids.map do |post_id|
            { post_id: post_id, user_id: current_user.id, created_at: now }
          end
        IsbfViews::PostImpression.insert_all(
          rows,
          unique_by: :index_isbf_post_view_impressions_on_post_id_and_user_id,
        )
        counts = IsbfViews::PostImpression.where(post_id: visible_ids).group(:post_id).count
      end

      render json: { counts: visible_ids.to_h { |id| [id, counts.fetch(id, 0)] } }
    end
  end

  IsbfViews::Engine.routes.draw do
    post "/impressions" => "impressions#create"
    post "/post-impressions" => "post_impressions#create"
  end
  Discourse::Application.routes.append { mount ::IsbfViews::Engine, at: "/isbf/views" }
end
