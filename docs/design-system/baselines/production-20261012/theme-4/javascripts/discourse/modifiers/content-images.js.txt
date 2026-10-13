import { modifier } from "ember-modifier";
import { themePrefix } from "virtual:theme";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import { decorateContentImages } from "../lib/content-images";

export default modifier((element) =>
  decorateContentImages(element, {
    onError: popupAjaxError,
    previewLabel: i18n(themePrefix("isbf_v2.preview_image")),
    retryLabel: i18n(themePrefix("isbf_v2.image_retry")),
  }),
);
