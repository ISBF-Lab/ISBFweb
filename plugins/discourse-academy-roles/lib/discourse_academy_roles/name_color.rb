# frozen_string_literal: true

module DiscourseAcademyRoles::NameColor
  ENABLED_FIELD = "academy_name_color_enabled"
  COLOR_FIELD = "academy_name_color"
  FIELDS = [ENABLED_FIELD, COLOR_FIELD].freeze
  HEX_COLOR = /\A#?(?:[0-9a-f]{3}|[0-9a-f]{6})\z/i
  GRADIENT_COLOR =
    /\Alinear-gradient\((90|180)deg,\s*(#[0-9a-f]{3}(?:[0-9a-f]{3})?),\s*(#[0-9a-f]{3}(?:[0-9a-f]{3})?)\)\z/i

  class Cache < ActiveSupport::CurrentAttributes
    attribute :selections
  end

  def self.enabled?(value)
    value == true || HasCustomFields::Helpers::CUSTOM_FIELD_TRUE.include?(value)
  end

  def self.normalize(value)
    return if value.blank?
    return unless value.is_a?(String) && value.length <= 80

    if gradient = GRADIENT_COLOR.match(value)
      return(
        "linear-gradient(#{gradient[1]}deg, #{normalize(gradient[2])}, #{normalize(gradient[3])})"
      )
    end
    return unless HEX_COLOR.match?(value)

    hex = value.delete_prefix("#").downcase
    hex = hex.chars.map { |character| character * 2 }.join if hex.length == 3
    "##{hex}"
  end

  def self.eligible?(user)
    SiteSetting.academy_roles_enabled? && user.is_a?(User) && user.id&.positive? &&
      (developer?(user) || (user.has_attribute?(:moderator) && user[:moderator]))
  end

  def self.developer?(user)
    user.is_a?(User) && user.has_attribute?(:admin) && user[:admin]
  end

  def self.allowed?(user)
    eligible?(user) && !selection(user)[:anonymous]
  end

  def self.customizable?(user)
    allowed?(user) && developer?(user)
  end

  def self.preload(users)
    cache = Cache.selections ||= {}
    missing = users.select { |user| eligible?(user) && !cache.key?(user.id) }.uniq(&:id)
    return if missing.empty?

    ids = missing.map(&:id)
    fields = User.custom_fields_for_ids(ids, FIELDS)
    anonymous = AnonymousUser.where(user_id: ids).pluck(:user_id)
    if defined?(IsbfAnonymous::PoolAccount)
      anonymous.concat(IsbfAnonymous::PoolAccount.where(user_id: ids).pluck(:user_id))
    end

    missing.each do |user|
      values = fields.fetch(user.id, {})
      cache[user.id] = {
        enabled: enabled?(values[ENABLED_FIELD]),
        color: normalize(values[COLOR_FIELD]),
        anonymous: anonymous.include?(user.id),
      }
    end
  end

  def self.selection(user)
    preload([user])
    (Cache.selections || {})[user.id] || { enabled: false, color: nil, anonymous: false }
  end

  def self.preferences(user)
    selection(user).slice(:enabled, :color)
  end

  def self.effective_color(user)
    return unless allowed?(user) && selection(user)[:enabled]

    (developer?(user) && selection(user)[:color]) || "theme"
  end

  def self.changed_fields(user, fields)
    fields.select do |name, value|
      previous = user.custom_fields[name]
      if name == ENABLED_FIELD
        enabled?(value) != enabled?(previous)
      else
        (normalize(value) || value.presence) != (normalize(previous) || previous.presence)
      end
    end
  end

  def self.validate(user)
    return if user.custom_fields_clean?

    previous =
      user.persisted? ? User.custom_fields_for_ids([user.id], FIELDS).fetch(user.id, {}) : {}
    fields = user.custom_fields

    if fields[ENABLED_FIELD] != previous[ENABLED_FIELD]
      value = fields[ENABLED_FIELD]
      valid_boolean = [nil, true, false, "false", "f", "0"].include?(value) || enabled?(value)
      changed = enabled?(value) != enabled?(previous[ENABLED_FIELD])
      if !valid_boolean || (changed && enabled?(value) && !allowed?(user))
        user.errors.add(:base, I18n.t("academy_roles.name_color.unavailable"))
      else
        fields[ENABLED_FIELD] = enabled?(value)
      end
    end

    if fields[COLOR_FIELD] != previous[COLOR_FIELD]
      value = fields[COLOR_FIELD]
      changed =
        (normalize(value) || value.presence) !=
          (normalize(previous[COLOR_FIELD]) || previous[COLOR_FIELD].presence)
      if changed && !customizable?(user)
        user.errors.add(:base, I18n.t("academy_roles.name_color.custom_unavailable"))
      elsif value.present? && !normalize(value)
        user.errors.add(:base, I18n.t("academy_roles.name_color.invalid_color"))
      else
        fields[COLOR_FIELD] = normalize(value)
      end
    end

    Cache.reset
  end

  module UserLookupPreloader
    private

    def users
      result = super
      DiscourseAcademyRoles::NameColor.preload(result.values)
      result
    end
  end

  module UserUpdaterExtension
    def update(attributes = {})
      name_color = DiscourseAcademyRoles::NameColor
      if SiteSetting.academy_roles_enabled? && attributes[:custom_fields].present?
        fields = attributes[:custom_fields].to_h.stringify_keys.slice(*FIELDS)
        changes = name_color.changed_fields(@user, fields)
        if changes.present?
          raise Discourse::InvalidAccess if @actor&.id != @user.id
          if changes.key?(ENABLED_FIELD) && name_color.enabled?(changes[ENABLED_FIELD])
            raise Discourse::InvalidAccess unless @guardian.can_wear_academy_name_color?(@user)
          end
          if changes.key?(COLOR_FIELD)
            raise Discourse::InvalidAccess unless @guardian.can_customize_academy_name_color?(@user)
          end
        end
      end

      super
    end
  end
end
