# frozen_string_literal: true

module IsbfModeration
  module AiModes
    class InvalidConfiguration < StandardError
    end

    class Conflict < StandardError
    end

    SETTING = :isbf_ai_moderation_modes
    LOCK = "isbf-ai-moderation-modes"
    CATEGORIES = %w[fraud harassment privacy sexual].freeze
    LEVELS = %w[lenient standard strict].freeze
    REVIEW_ONLY = "review_only"
    HIDE_AND_REVIEW = "hide_and_review"
    ACTIONS = [REVIEW_ONLY, HIDE_AND_REVIEW].freeze
    MAX_POLICY_LENGTH = 2_000

    DEFAULT_CRITERIA = {
      "fraud" => %w[
        送审有明确证据的诈骗或钓鱼。例如冒充校方，引导读者向未经证实的页面提交账号密码。
        也送审明显与讨论无关的商业垃圾广告。例如在课程答疑下推销与课程无关的充值服务。
        也送审与话题略有关联、但内容仅用于招揽交易或引流的推广回复。
      ].freeze,
      "harassment" => %w[
        送审明确的人身威胁或严重骚扰。例如以伤害对方的人身安全相威胁。
        也送审针对特定个人或群体的严重辱骂。
        也送审对象明确、程度较轻的辱骂或羞辱。例如争论中只回复对方『你这人真蠢』。
      ].freeze,
      "privacy" => %w[
        送审明确披露能对应到他人的非公开证件号、住址或金融信息。例如未经同意贴出同学的完整住址。
        也送审披露他人其他非公开敏感个人信息的内容，包括私人联系方式。
        也送审能凭帖内可见线索还原的部分遮挡或碎片化的非公开敏感个人信息。
      ].freeze,
      "sexual" => %w[
        送审以性刺激为主要目的、明确展示或具体描述性行为的内容。
        也送审其他明确的露骨色情内容。例如以色情传播为目的分享露骨性的图文内容。
        也送审以性刺激为主要目的、有直接性暗示的展示。
      ].freeze,
    }.freeze

    DEFAULT_EXCLUSIONS = {
      "fraud" => "放行正常的资料分享、课程讨论、相关产品介绍和反诈讨论。例如附有参考链接的学习资料。",
      "harassment" => "放行合理批评、正常争论及教育引用。例如『这个方案很差』是对方案的评价。",
      "privacy" => "放行本人主动公开的信息以及无法识别具体个人的脱敏案例。",
      "sexual" => "放行医学、教育和新闻语境中的正常说明或引用。",
    }.freeze

    def self.defaults
      CATEGORIES.to_h do |category|
        profiles =
          LEVELS.each_with_index.to_h do |level, index|
            criteria = DEFAULT_CRITERIA.fetch(category).take(index + 1)
            policy = (criteria + [DEFAULT_EXCLUSIONS.fetch(category)]).join("\n")
            [level, { "policy" => policy, "action" => HIDE_AND_REVIEW }]
          end
        [category, { "active_level" => "standard", "profiles" => profiles }]
      end
    end

    def self.effective
      parse(stored_value).transform_values do |category|
        level = category.fetch("active_level")
        category.fetch("profiles").fetch(level).merge("level" => level)
      end
    end

    def self.revision(value)
      Digest::SHA256.hexdigest(value.to_json)
    end

    def self.audit_context(modes)
      {
        modes: modes.transform_values { |mode| mode.slice("level", "action") },
        policy_revision: revision(modes),
      }
    end

    def self.response(configuration = parse(stored_value))
      {
        categories:
          configuration.transform_values do |category|
            category.merge("revision" => revision(category))
          end,
        defaults: defaults,
        max_policy_length: MAX_POLICY_LENGTH,
      }
    end

    def self.save!(input, guardian:)
      unless keys?(input, %w[category revision active_level profiles]) &&
               CATEGORIES.include?(input["category"]) && input["revision"].is_a?(String)
        raise InvalidConfiguration
      end

      category = input.fetch("category")
      replacement = normalize_category(input.slice("active_level", "profiles"))

      synchronize do
        previous_value = stored_value
        configuration = parse(previous_value)
        current = configuration.fetch(category)
        raise Conflict unless revision(current) == input["revision"]

        if current != replacement
          configuration[category] = replacement
          SiteSetting.refresh! if SiteSetting.public_send(SETTING) != previous_value
          SiteSetting.transaction do
            # The native setting updater skips operation logs for hidden settings.
            StaffActionLogger.new(guardian.user).log_site_setting_change(
              SETTING,
              audit_summary(category, current),
              audit_summary(category, replacement),
            )
            SiteSetting::Update.call(
              guardian: guardian,
              params: {
                settings: [{ setting_name: SETTING, value: configuration.to_json }],
              },
              options: {
                allow_changing_hidden: [SETTING],
                expected_values: {
                  SETTING => previous_value,
                },
              },
            ) do
              on_success { configuration }
              on_failed_policy(:current_user_is_admin) { raise Discourse::InvalidAccess }
              on_exceptions(SiteSetting::Update::Conflict) { raise Conflict }
              on_failure { raise InvalidConfiguration }
            end
          end
        end

        response(configuration)
      end
    end

    def self.synchronize(&block)
      DistributedMutex.synchronize(LOCK, &block)
    end

    def self.parse(value)
      return defaults if value == ""
      raise InvalidConfiguration unless value.is_a?(String)
      configuration = JSON.parse(value)
      raise InvalidConfiguration unless keys?(configuration, CATEGORIES)
      CATEGORIES.to_h { |category| [category, normalize_category(configuration.fetch(category))] }
    rescue JSON::ParserError
      raise InvalidConfiguration
    end

    def self.audit_summary(category, configuration)
      {
        category: category,
        active_level: configuration.fetch("active_level"),
        revision: revision(configuration),
      }.to_json
    end
    private_class_method :audit_summary

    def self.stored_value
      SiteSetting.provider.find(SETTING)&.value.to_s
    end
    private_class_method :stored_value

    def self.normalize_category(category)
      unless keys?(category, %w[active_level profiles]) &&
               LEVELS.include?(category["active_level"]) && keys?(category["profiles"], LEVELS)
        raise InvalidConfiguration
      end

      profiles =
        LEVELS.to_h do |level|
          profile = category["profiles"].fetch(level)
          unless keys?(profile, %w[policy action]) && profile["policy"].is_a?(String) &&
                   profile["policy"].present? && profile["policy"].length <= MAX_POLICY_LENGTH &&
                   ACTIONS.include?(profile["action"])
            raise InvalidConfiguration
          end
          [level, { "policy" => profile["policy"], "action" => profile["action"] }]
        end
      { "active_level" => category["active_level"], "profiles" => profiles }
    end
    private_class_method :normalize_category

    def self.keys?(value, keys)
      value.is_a?(Hash) && value.size == keys.size && keys.all? { |key| value.key?(key) }
    end
    private_class_method :keys?
  end

  class AiModesValidator
    def initialize(_options = {})
    end

    def valid_value?(value)
      AiModes.parse(value)
      true
    rescue AiModes::InvalidConfiguration
      false
    end

    def error_message
      I18n.t("isbf_moderation.ai.modes.invalid", maximum: AiModes::MAX_POLICY_LENGTH)
    end
  end
end
