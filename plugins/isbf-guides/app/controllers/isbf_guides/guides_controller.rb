# frozen_string_literal: true

module ::IsbfGuides
  class GuidesController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login
    prepend_before_action :guide_login_redirect, only: %i[index show]
    skip_before_action :check_xhr, only: %i[index show image]
    before_action :private_response

    def index
      respond_to do |format|
        format.html { render "default/empty" }
        format.json do
          page = [params[:page].to_i, 1].max
          guides =
            Guide
              .published
              .joins(:published_revision)
              .includes(:published_revision)
              .order("isbf_guides_revisions.published_at DESC", :id)
              .offset((page - 1) * 30)
              .limit(31)
              .to_a
          render json: {
                   guides: serialize_data(guides.first(30), GuideSummarySerializer),
                   page:,
                   has_more: guides.length > 30,
                 }
        end
      end
    end

    def show
      preview = params[:preview] == "1"
      raise Discourse::NotFound if preview && !guardian.can_manage_isbf_guides?
      guide = Guide.includes(:draft_revision, :published_revision).find_by!(slug: params[:slug])
      raise Discourse::NotFound unless preview ? guide.draft_revision : guide.published_revision

      respond_to do |format|
        format.html { render "default/empty" }
        format.json do
          render json: {
                   guide:
                     GuideSerializer.new(guide, root: false, scope: guardian, preview:).as_json,
                 }
        end
      end
    end

    def image
      guide = Guide.find_by!(slug: params[:slug])
      image =
        guide.images.select(:id, :filename, :content_type).find_by!(filename: params[:filename])
      unless guardian.can_manage_isbf_guides? ||
               guide.published_revision&.image_ids&.include?(image.id)
        raise Discourse::NotFound
      end
      data = Image.where(id: image.id).pick(:data)
      response.headers["X-Content-Type-Options"] = "nosniff"
      response.headers["Content-Security-Policy"] = "default-src 'none'; sandbox"
      send_data data, type: image.content_type, disposition: :inline, filename: image.filename
    end

    private

    def guide_login_redirect
      redirect_to_login if request.format.html? && !current_user
    end

    def private_response
      response.headers["Cache-Control"] = "private, no-store"
      response.headers["X-Robots-Tag"] = "noindex, nofollow"
    end
  end
end
