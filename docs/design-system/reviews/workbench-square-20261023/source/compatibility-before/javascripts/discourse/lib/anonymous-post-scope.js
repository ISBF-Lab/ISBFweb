import Category from "discourse/models/category";
import { isCareersCategory } from "./careers";
import { marketplaceConfig } from "./marketplace";
import { isTeamupCategory } from "./teamup";

export function canPublishAnonymously(model, currentUser, siteSettings) {
  if (
    !model ||
    !currentUser?.can_post_anonymously ||
    currentUser.is_anonymous ||
    isTeamupCategory(model) ||
    isCareersCategory(model) ||
    !["createTopic", "reply"].includes(model.action) ||
    model.archetypeId === "private_message" ||
    [true, "true"].includes(model.academy_official)
  ) {
    return false;
  }

  if (
    model.action === "reply" &&
    model.topic?.archetype === "private_message"
  ) {
    return false;
  }

  const categoryId =
    model.action === "reply"
      ? (model.topic?.category_id ?? model.topic?.category?.id)
      : model.categoryId;
  const category = categoryId ? Category.findById(categoryId) : null;
  if (marketplaceConfig(model.site)?.category_id === Number(categoryId)) {
    return false;
  }

  const officialCategoryId = Number(siteSettings.academy_official_category);

  return (
    !category?.read_restricted &&
    !(officialCategoryId > 0 && Number(categoryId) === officialCategoryId)
  );
}
