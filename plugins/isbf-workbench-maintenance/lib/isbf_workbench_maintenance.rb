# frozen_string_literal: true

module ::IsbfWorkbenchMaintenance
  ENTRY_KEYS = %w[
    learning_resources
    library
    courses
    careers
    resume
    campus_services
    student_identity
    alumni
    marketplace
    teamup
    mbti
    ai_assistant
    guides
  ].freeze

  def self.paused?(key)
    key = key.to_s
    ENTRY_KEYS.include?(key) && SiteSetting.public_send("isbf_workbench_pause_#{key}")
  end

  def self.ensure_available!(key)
    raise Discourse::NotFound if paused?(key)
  end
end
