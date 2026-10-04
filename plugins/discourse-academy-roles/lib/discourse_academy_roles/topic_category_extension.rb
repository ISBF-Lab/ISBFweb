# frozen_string_literal: true

module DiscourseAcademyRoles::TopicCategoryExtension
  def changed_to_category(new_category, silent: nil)
    if SiteSetting.academy_roles_enabled? && new_category.present? &&
         !DiscourseAcademyRoles.valid_topic_category?(self, new_category.id)
      errors.add(:category_id, I18n.t("academy_roles.official_category_move"))
      return false
    end

    super
  end
end
