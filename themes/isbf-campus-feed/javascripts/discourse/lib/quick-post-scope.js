import { settings } from "virtual:theme";

export function isQuickPost(model) {
  const eventCategoryId = Number(settings.calendar_category_id);

  return (
    model?.action === "createTopic" &&
    !model.creatingEvent &&
    !(eventCategoryId > 0 && Number(model.categoryId) === eventCategoryId) &&
    Boolean(document.querySelector(".isbf-v2-shell"))
  );
}
