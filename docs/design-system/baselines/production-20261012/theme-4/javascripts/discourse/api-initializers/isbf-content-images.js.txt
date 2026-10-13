import { themePrefix } from "virtual:theme";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import { decorateContentImages } from "../lib/content-images";

export default apiInitializer((api) => {
  const router = api.container.lookup("service:router");
  const decorate = (element, helper) => {
    if (/^\/admin(?:\/|$)/.test(router.currentURL)) {
      return;
    }
    return decorateContentImages(element, {
      onError: popupAjaxError,
      post: helper?.model,
      previewLabel: i18n(themePrefix("isbf_v2.preview_image")),
      retryLabel: i18n(themePrefix("isbf_v2.image_retry")),
    });
  };
  api.decorateCookedElement(decorate, { id: "isbf-content-images" });
  api.decorateChatMessage?.(decorate, { id: "isbf-content-images" });
});
