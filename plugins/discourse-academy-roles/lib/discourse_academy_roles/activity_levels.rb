# frozen_string_literal: true

module DiscourseAcademyRoles::ActivityLevels
  CONFIG_KEY = "activity_levels:configuration"
  RUN_KEY = "activity_levels:recalculation"
  STATE_PREFIX = "activity_levels:user:"
  LEVEL_ID_FIELD = "academy_activity_level_id"
  LOCK_KEY = "academy-activity-levels:configuration"
  BATCH_SIZE = 100

  class Conflict < StandardError
  end

  class InvalidConfiguration < StandardError
  end

  class UnconfirmedDeletion < StandardError
  end

  class ReferencedLevel < StandardError
  end

  class Current < ActiveSupport::CurrentAttributes
    attribute :configuration
  end

  def self.accounts
    users = User.where("users.id > 0").where(staged: false)
    users = users.where.not(id: AnonymousUser.select(:user_id))
    if defined?(IsbfAnonymous::PoolAccount)
      users = users.where.not(id: IsbfAnonymous::PoolAccount.select(:user_id))
    end
    users
  end

  def self.eligible_accounts
    accounts.where(active: true)
  end

  def self.synchronize
    PluginStoreRow.transaction do
      DB.exec("SELECT pg_advisory_xact_lock(hashtext(:key))", key: LOCK_KEY)
      yield
    end
  end

  def self.write!(key, value)
    unless PluginStore.set(DiscourseAcademyRoles::PLUGIN_NAME, key, value)
      raise ActiveRecord::RecordNotSaved, "Could not save activity level state"
    end
  end

  def self.read(key)
    PluginStore.get(DiscourseAcademyRoles::PLUGIN_NAME, key)
  end

  def self.display_level(user)
    configuration = Current.configuration ||= Configuration.current
    identifier = user.custom_fields[LEVEL_ID_FIELD]
    level = configuration.levels.find { |entry| entry["id"] == identifier }
    if identifier.blank? || configuration.revision.zero?
      level =
        configuration.levels[user.custom_fields[DiscourseAcademyRoles::ACTIVITY_LEVEL_FIELD].to_i]
    end
    level || configuration.levels.first
  end

  def self.level_number(user)
    level = display_level(user)
    Current.configuration.levels.index(level) || 0
  end

  def self.level_name(user)
    display_level(user)["name"]
  end

  def self.initialize_user(user)
    return if user.staged? || user.is_system_user?

    synchronize do
      if Configuration.persisted? && user.custom_fields[LEVEL_ID_FIELD].blank?
        user.custom_fields[LEVEL_ID_FIELD] = Configuration.current.levels.first["id"]
        user.save_custom_fields
      end
    end
  end
end

require_relative "activity_levels/catalog"
require_relative "activity_levels/configuration"
require_relative "activity_levels/cosmetics"
require_relative "activity_levels/level_badges"
require_relative "activity_levels/metrics"
require_relative "activity_levels/evaluator"
require_relative "activity_levels/recalculation"
