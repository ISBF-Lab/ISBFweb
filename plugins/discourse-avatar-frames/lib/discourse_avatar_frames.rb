# frozen_string_literal: true

module DiscourseAvatarFrames
  FIELD = "avatar_frame"
  class Cache < ActiveSupport::CurrentAttributes
    attribute :frames, :catalog
  end

  def self.catalog
    Cache.catalog ||=
      Frame.active.includes(:image_upload, :static_upload).order(:position, :id).to_a
  end

  def self.anonymous_ids(ids)
    result = AnonymousUser.where(user_id: ids).pluck(:user_id)
    if defined?(IsbfAnonymous::PoolAccount)
      result.concat(IsbfAnonymous::PoolAccount.where(user_id: ids).pluck(:user_id))
    end
    result
  end

  def self.anonymous?(user)
    !user.id.positive? || anonymous_ids([user.id]).include?(user.id)
  end

  def self.allowed?(user, frame_key)
    Frame.available_for(user).exists?(key: frame_key)
  end

  def self.preload(users)
    return unless SiteSetting.avatar_frames_enabled
    cache = Cache.frames ||= {}
    missing = users.select { |user| user.is_a?(User) && !cache.key?(user.id) }.uniq(&:id)
    return if missing.empty?
    ids = missing.map(&:id)
    selections = UserCustomField.where(user_id: ids, name: FIELD).pluck(:user_id, :value).to_h
    anonymous = anonymous_ids(ids)
    frames = catalog.index_by(&:key)
    awarded = Grant.where(user_id: ids).pluck(:user_id, :frame_id).group_by(&:first)
    missing.each do |user|
      frame = frames[selections[user.id]]
      permitted =
        user.id.positive? && !anonymous.include?(user.id) && frame &&
          (
            frame.access_mode == "public" ||
              awarded.fetch(user.id, []).any? { |_, frame_id| frame_id == frame.id }
          )
      cache[user.id] = permitted ? frame.key : nil
    end
  end

  def self.frame_for(user)
    return unless SiteSetting.avatar_frames_enabled && user.is_a?(User)
    preload([user])
    Cache.frames[user.id]
  end

  module UserLookupPreloader
    private

    def users
      result = super
      DiscourseAvatarFrames.preload(result.values)
      result
    end
  end

  module LinkedAccounts
    private

    def serialize_link(link)
      if SiteSetting.avatar_frames_enabled && !@avatar_frames_preloaded
        links = IsbfAccountSwitch::AccountLink.for_user(current_user.id).includes(:user_a, :user_b)
        DiscourseAvatarFrames.preload(
          links.map { |account_link| account_link.other_user(current_user) },
        )
        @avatar_frames_preloaded = true
      end
      result = super
      if result && SiteSetting.avatar_frames_enabled
        result[:account][:avatar_frame] = DiscourseAvatarFrames.frame_for(
          link.other_user(current_user),
        )
      end
      result
    end
  end
end
