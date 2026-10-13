# frozen_string_literal: true

module DiscourseAvatarFrames
  class GrantSerializer < ::ApplicationSerializer
    attributes :id, :granted_at
    has_one :user, serializer: ::BasicUserSerializer, embed: :object
    has_one :granted_by, serializer: ::BasicUserSerializer, embed: :object
  end
end
