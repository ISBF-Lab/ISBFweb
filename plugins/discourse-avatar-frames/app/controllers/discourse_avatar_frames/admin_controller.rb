# frozen_string_literal: true

module DiscourseAvatarFrames
  class AdminController < ::ApplicationController
    requires_plugin "discourse-avatar-frames"
    before_action :ensure_logged_in
    before_action :ensure_admin
  end
end
