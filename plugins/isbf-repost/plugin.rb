# frozen_string_literal: true

# name: isbf-repost
# about: Records quote repost relationships and exposes visibility-aware counts.
# version: 0.1.0
# authors: ISBF Lab
# url: https://github.com/ISBF-Lab/ISBF-Repost
# required_version: 3.2.0

enabled_site_setting :isbf_repost_enabled

after_initialize do
  add_permitted_post_create_param(:isbf_repost_source_topic_id, :integer)
  allow_new_queued_post_payload_attribute(:isbf_repost_source_topic_id)

  module ::IsbfRepost
    PLUGIN_NAME = "isbf-repost"

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace IsbfRepost
    end

    class Repost < ::ActiveRecord::Base
      self.table_name = "isbf_reposts"

      belongs_to :repost_topic, class_name: "Topic"
      belongs_to :source_topic, class_name: "Topic"
      belongs_to :user
    end
  end

  class ::IsbfRepost::CountsController < ::ApplicationController
    MAX_TOPICS = 50

    def index
      raise Discourse::NotFound unless SiteSetting.isbf_repost_enabled

      topic_ids = Array(params[:topic_ids]).filter_map { |id| Integer(id, exception: false) }.uniq
      raise Discourse::InvalidParameters.new(:topic_ids) if topic_ids.length > MAX_TOPICS

      visible_source_ids = visible_topics.where(id: topic_ids).pluck(:id)
      relations =
        IsbfRepost::Repost
          .where(source_topic_id: visible_source_ids)
          .joins(:repost_topic)
          .where(topics: { deleted_at: nil })
      visible_repost_ids = visible_topics.where(id: relations.select(:repost_topic_id)).pluck(:id)
      counts = relations.where(repost_topic_id: visible_repost_ids).group(:source_topic_id).count

      render json: { counts: topic_ids.to_h { |id| [id, counts.fetch(id, 0)] } }
    end

    private

    def visible_topics
      Topic.listable_topics.secured(guardian)
    end
  end

  IsbfRepost::Engine.routes.draw { get "/counts" => "counts#index" }
  Discourse::Application.routes.append { mount ::IsbfRepost::Engine, at: "/isbf/reposts" }

  NewPostManager.add_handler(5) do |manager|
    next unless SiteSetting.isbf_repost_enabled

    source_topic_id =
      manager.args[:isbf_repost_source_topic_id] || manager.args["isbf_repost_source_topic_id"]
    next if source_topic_id.blank?

    result = NewPostResult.new(:isbf_repost, false)
    source_topic = Topic.find_by(id: source_topic_id)
    can_repost =
      source_topic && manager.args[:topic_id].blank? &&
        manager.args[:archetype] != Archetype.private_message &&
        Guardian.new(manager.user).can_see?(source_topic)

    unless can_repost
      result.add_error(I18n.t("isbf_repost.errors.invalid_source"))
      next result
    end

    nil
  end

  on(:post_created) do |post, opts, user|
    next unless SiteSetting.isbf_repost_enabled

    source_topic_id = opts[:isbf_repost_source_topic_id] || opts["isbf_repost_source_topic_id"]
    next if source_topic_id.blank? || post.post_number != 1

    source_topic = Topic.find_by(id: source_topic_id)
    next unless source_topic && Guardian.new(user).can_see?(source_topic)

    IsbfRepost::Repost.find_or_create_by!(
      repost_topic_id: post.topic_id,
      source_topic_id: source_topic.id,
    ) { |repost| repost.user_id = user.id }
  end
end
