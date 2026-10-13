# frozen_string_literal: true

# name: discourse-avatar-frames
# about: Uploadable avatar frames with individual and CSV awards
# version: 0.4.0
# authors: asa0w0, ISBF Lab
# url: https://github.com/asa0w0/discourse-avatar-frames

enabled_site_setting :avatar_frames_enabled
register_asset "stylesheets/common/avatar-frames.scss"
register_asset "stylesheets/common/avatar-frames-admin.scss", :admin
add_admin_route "avatar_frames.admin.title", "discourse-avatar-frames", use_new_show_route: true

module ::DiscourseAvatarFrames
  BUILTINS = {
    "dream-dive-stars" => "Dream Dive Stars",
    "head-in-the-clouds-sunset" => "Head in the Clouds",
    "sakura-pink" => "Sakura Pink",
    "chromawave" => "Chromawave",
    "bubble" => "Bubble",
    "terrarium" => "Terrarium",
  }.freeze
end

require_relative "lib/discourse_avatar_frames/engine"
register_seedfu_fixtures File.join(__dir__, "db/fixtures")

after_initialize do
  require_relative "lib/discourse_avatar_frames"
  require_relative "lib/discourse_avatar_frames/png"
  require_relative "lib/discourse_avatar_frames/image_analysis"
  require_relative "lib/discourse_avatar_frames/upload_creator"
  require_relative "lib/discourse_avatar_frames/csv_recipients"
  UploadSecurity.register_custom_public_type("avatar_frame")

  User.register_custom_field_type(DiscourseAvatarFrames::FIELD, :string, max_length: 64)
  register_editable_user_custom_field(DiscourseAvatarFrames::FIELD)
  allow_public_user_custom_field(DiscourseAvatarFrames::FIELD)

  add_model_callback(:user, :validate) do
    next if custom_fields_clean?

    frame = custom_fields[DiscourseAvatarFrames::FIELD]
    previous =
      if persisted?
        UserCustomField.where(user_id: id, name: DiscourseAvatarFrames::FIELD).pick(:value)
      end
    next if frame == previous || frame.blank? || frame == "none"

    unless DiscourseAvatarFrames.allowed?(self, frame)
      errors.add(:base, I18n.t("avatar_frames.errors.unavailable"))
    end
  end

  add_to_serializer(:basic_user, :avatar_frame) { DiscourseAvatarFrames.frame_for(user) }
  add_to_serializer(:post, :user_avatar_frame) { DiscourseAvatarFrames.frame_for(object.user) }
  add_to_serializer(:site, :avatar_frames) do
    ActiveModel::ArraySerializer.new(
      DiscourseAvatarFrames.catalog,
      each_serializer: DiscourseAvatarFrames::FrameSerializer,
      scope:,
      root: false,
    ).as_json
  end
  add_to_serializer(
    :user,
    :available_avatar_frames,
    include_condition: -> { scope.can_edit?(object) },
  ) { DiscourseAvatarFrames::Frame.available_for(object).pluck(:key) }
  add_to_serializer(:current_user, :available_avatar_frames) do
    DiscourseAvatarFrames::Frame.available_for(object).pluck(:key)
  end

  UserLookup.prepend(DiscourseAvatarFrames::UserLookupPreloader)
  TopicView.on_preload { |view| DiscourseAvatarFrames.preload(view.posts.map(&:user).compact) }

  on(:user_updated) { DiscourseAvatarFrames::Cache.reset }
  on(:site_setting_changed) do |name, _old_value, _new_value|
    DiscourseAvatarFrames::Cache.reset if name.to_s.start_with?("avatar_frames_")
  end
  on(:user_destroyed) { |user| DiscourseAvatarFrames::Grant.where(user_id: user.id).delete_all }

  account_switch = Discourse.plugins.find { |plugin| plugin.name == "isbf-account-switch" }
  if account_switch
    require File.join(
              account_switch.directory,
              "app/controllers/isbf_account_switch/accounts_controller",
            )
    IsbfAccountSwitch::AccountsController.prepend(DiscourseAvatarFrames::LinkedAccounts)
  end
end
