# frozen_string_literal: true

module DiscourseAcademyRoles::ActivityLevels
  module Cosmetics
    class Cache < ActiveSupport::CurrentAttributes
      attribute :accounts
    end

    def self.defaults
      {
        "avatar_minimum_level_id" => "legacy-0",
        "name_color_enabled" => false,
        "name_color_minimum_level_id" => "legacy-0",
        "name_color_light" => "",
        "name_color_dark" => "",
      }
    end

    def self.configuration
      Current.configuration ||= Configuration.current
    end

    def self.staff?(user)
      user.is_a?(User) &&
        (
          (user.has_attribute?(:admin) && user[:admin]) ||
            (user.has_attribute?(:moderator) && user[:moderator])
        )
    end

    def self.preload(users)
      cache = Cache.accounts ||= {}
      missing = users.select { |user| user.is_a?(User) && !cache.key?(user.id) }.uniq(&:id)
      return if missing.empty?

      ids = missing.map(&:id)
      fields =
        User.custom_fields_for_ids(
          ids,
          [LEVEL_ID_FIELD, DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD],
        )
      anonymous = AnonymousUser.where(user_id: ids).pluck(:user_id)
      if defined?(IsbfAnonymous::PoolAccount)
        anonymous.concat(IsbfAnonymous::PoolAccount.where(user_id: ids).pluck(:user_id))
      end
      eligible = User.where(id: ids, staged: false).where("id > 0").pluck(:id) - anonymous
      missing.each do |user|
        values = fields.fetch(user.id, {})
        index = configuration.levels.index { |entry| entry["id"] == values[LEVEL_ID_FIELD] }
        if values[LEVEL_ID_FIELD].blank? || configuration.revision.zero?
          index = values[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD].to_i
          index = 0 unless configuration.levels[index]
        end
        cache[user.id] = { eligible: eligible.include?(user.id), number: index || 0 }
      end
    end

    def self.account(user)
      preload([user])
      (Cache.accounts || {})[user&.id] || { eligible: false, number: 0 }
    end

    def self.level_info(identifier)
      index = configuration.levels.index { |level| level["id"] == identifier }
      return unless index

      { id: identifier, number: index, name: configuration.levels[index]["name"] }
    end

    def self.minimum_met?(user, identifier)
      requirement = level_info(identifier)
      requirement && account(user)[:number] >= requirement[:number]
    end

    def self.avatar_allowed?(user, minimum_level_id = nil)
      return false unless account(user)[:eligible]
      return true if staff?(user)

      minimum_met?(user, configuration.cosmetics["avatar_minimum_level_id"]) &&
        (minimum_level_id.blank? || minimum_met?(user, minimum_level_id))
    end

    def self.name_color_allowed?(user)
      SiteSetting.academy_roles_enabled? && account(user)[:eligible] &&
        configuration.cosmetics["name_color_enabled"] &&
        minimum_met?(user, configuration.cosmetics["name_color_minimum_level_id"])
    end

    def self.name_colors
      values = configuration.cosmetics
      if SiteSetting.academy_roles_enabled? && values["name_color_enabled"]
        { light: values["name_color_light"], dark: values["name_color_dark"] }
      end
    end

    def self.capabilities(user)
      {
        avatar_frames: {
          unlocked: avatar_allowed?(user),
          minimum_level: level_info(configuration.cosmetics["avatar_minimum_level_id"]),
        },
        name_color: {
          configured: configuration.cosmetics["name_color_enabled"],
          unlocked: name_color_allowed?(user) || (staff?(user) && account(user)[:eligible]),
          minimum_level: level_info(configuration.cosmetics["name_color_minimum_level_id"]),
        },
      }
    end

    def self.valid?(values, levels)
      return false unless values.is_a?(Hash) && (values.keys - defaults.keys).empty?
      return false if [true, false].exclude?(values["name_color_enabled"])
      ids = levels.filter_map { |level| level["id"] if level.is_a?(Hash) }
      unless %w[avatar_minimum_level_id name_color_minimum_level_id].all? { |key|
               ids.include?(values[key])
             }
        return false
      end

      %w[name_color_light name_color_dark].all? do |key|
        value = values[key]
        value.is_a?(String) &&
          ((value.empty? && !values["name_color_enabled"]) || /\A#[0-9a-f]{6}\z/i.match?(value))
      end
    end
  end
end
