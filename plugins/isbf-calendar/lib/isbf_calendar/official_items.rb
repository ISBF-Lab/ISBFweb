# frozen_string_literal: true

module IsbfCalendar
  OFFICIAL_ITEMS_FIELD = "isbf_official_calendar_items"
  TIMEZONE = "Asia/Shanghai"
  MAX_OFFICIAL_ITEMS = 20
  MAX_PAYLOAD_BYTES = 32_768

  def self.official_category_id
    unless defined?(DiscourseAcademyRoles) && SiteSetting.academy_roles_enabled?
      return
    end
    id = SiteSetting.academy_official_category.to_i
    id if id.positive?
  end

  def self.official_topic?(topic)
    official_category_id && topic.category_id == official_category_id &&
      topic.archetype == Archetype.default
  end

  def self.parse_official_items(value)
    if value.is_a?(String)
      raise Discourse::InvalidParameters if value.bytesize > MAX_PAYLOAD_BYTES
      value = JSON.parse(value)
    end
    unless value.is_a?(Array) && value.size <= MAX_OFFICIAL_ITEMS &&
             value.all? { |item| item.is_a?(Hash) }
      raise Discourse::InvalidParameters.new(OFFICIAL_ITEMS_FIELD)
    end
    value.map(&:with_indifferent_access)
  rescue JSON::ParserError
    raise Discourse::InvalidParameters.new(OFFICIAL_ITEMS_FIELD)
  end

  def self.publish_official_items(topic, user, value)
    result =
      PublishOfficialItems.call(
        params: {
          items: parse_official_items(value)
        },
        topic:,
        guardian: user.guardian
      )
    if result.failure?
      raise Discourse::InvalidParameters.new(
              I18n.t("isbf_calendar.invalid_items")
            )
    end
    result
  end
end
