# frozen_string_literal: true

Fabricator(:avatar_frame, class_name: "DiscourseAvatarFrames::Frame") do
  key { SecureRandom.uuid }
  name { sequence(:avatar_frame_name) { |number| "Campus frame #{number}" } }
  builtin "bubble"
  access_mode "granted"
end

Fabricator(:uploaded_avatar_frame, from: :avatar_frame) do
  builtin ""
  image_upload { Fabricate(:upload, width: 288, height: 288) }
  static_upload { |attributes| attributes[:image_upload] }
  confirm_calibration true
end

Fabricator(:avatar_frame_grant, class_name: "DiscourseAvatarFrames::Grant") do
  frame { Fabricate(:avatar_frame) }
  user
  granted_by { Fabricate(:admin) }
  granted_at { Time.current }
end

Fabricator(:avatar_frame_import, class_name: "DiscourseAvatarFrames::Import") do
  frame { Fabricate(:avatar_frame) }
  created_by { Fabricate(:admin) }
end

Fabricator(:avatar_frame_anonymous_identity, class_name: "AnonymousUser") do
  user
  master_user { Fabricate(:user) }
  active true
end
