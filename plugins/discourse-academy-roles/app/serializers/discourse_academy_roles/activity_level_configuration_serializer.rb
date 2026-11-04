# frozen_string_literal: true

class DiscourseAcademyRoles::ActivityLevelConfigurationSerializer < ApplicationSerializer
  attributes :revision,
             :allow_demotion,
             :levels,
             :catalog,
             :recalculation,
             :initialized,
             :cosmetics,
             :badge_options,
             :minimum_continuous_check_gap_hours

  def minimum_continuous_check_gap_hours
    DiscourseAcademyRoles::ActivityLevels::Configuration::MIN_CONTINUOUS_CHECK_GAP_HOURS
  end

  def cosmetics
    object.cosmetics
  end

  def badge_options
    DiscourseAcademyRoles::ActivityLevels::LevelBadges
      .available
      .order(:name)
      .pluck(:id, :name)
      .map { |id, name| { id: id, name: name } }
  end

  def revision
    object.revision
  end

  def allow_demotion
    object.allow_demotion?
  end

  def initialized
    DiscourseAcademyRoles::ActivityLevels::Configuration.persisted?
  end

  def levels
    counts = object.assigned_counts
    object.levels.each_with_index.map do |level, index|
      level.merge("number" => index, "assigned_users" => counts.fetch(level["id"], 0))
    end
  end

  def catalog
    DiscourseAcademyRoles::ActivityLevels::Catalog.definitions
  end

  def recalculation
    state = DiscourseAcademyRoles::ActivityLevels::Recalculation.current
    if state
      DiscourseAcademyRoles::ActivityLevelRecalculationSerializer.new(state, root: false).as_json
    end
  end
end
