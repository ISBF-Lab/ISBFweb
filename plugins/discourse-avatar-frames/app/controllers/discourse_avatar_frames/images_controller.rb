# frozen_string_literal: true

module DiscourseAvatarFrames
  class ImagesController < ::ApplicationController
    requires_plugin "discourse-avatar-frames"
    skip_before_action :check_xhr, :preload_json, :redirect_to_login_if_required

    def show
      frame = Frame.active.find_by(key: params[:key])
      raise Discourse::NotFound unless frame
      url = params[:static] ? frame.static_url : frame.image_url
      raise Discourse::NotFound if url.blank?
      redirect_to UrlHelper.cook_url(url), allow_other_host: true
    end
  end
end
