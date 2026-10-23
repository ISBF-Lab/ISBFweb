import { themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import Composer from "discourse/models/composer";
import { i18n } from "discourse-i18n";
import { ISBFCareersSalary } from "../components/isbf-careers-card";
import ISBFCareersComposer, {
  ISBFCareersHome,
} from "../components/isbf-careers-composer";
import {
  CAREERS_FIELDS,
  careersPayload,
  isCareersCategory,
  isCareersComposer,
  restoreCareers,
  validCareersSalary,
} from "../lib/careers";
import { extendComposerMethod } from "../lib/composer-model-extensions";
import { invalidateCookedPost } from "../lib/feed-post-loader";
import {
  isUntitledTopicTitle,
  prepareOptionalTopicTitle,
} from "../lib/optional-topic-title";
import { isQuickPost } from "../lib/quick-post-scope";

export default apiInitializer((api) => {
  const properties = ["isbfCareersSalaryPayload", "isbfCareersHomePayload"];
  CAREERS_FIELDS.forEach((field, index) => {
    Composer.serializeOnCreate(field, properties[index]);
    Composer.serializeOnUpdate(field, properties[index]);
    Composer.serializeToDraft(field, field);
    api.addModelGetter("composer", properties[index], function () {
      return careersPayload(this, field);
    });
  });
  extendComposerMethod(api, "clearState", function (next, ...args) {
    const result = next(...args);
    this.setProperties({
      isbf_careers_salary: null,
      isbf_careers_home: null,
    });
    return result;
  });
  extendComposerMethod(api, "open", function (next, options = {}) {
    return next(options).then((result) => {
      restoreCareers(this, options);
      return result;
    });
  });
  extendComposerMethod(api, "save", function (next, ...args) {
    if (
      isCareersComposer(this) &&
      (!this.title?.trim() ||
        isUntitledTopicTitle(this.title) ||
        !this.reply?.trim() ||
        !validCareersSalary(this.isbf_careers_salary))
    ) {
      return Promise.resolve(
        this.dialog.alert(i18n(themePrefix("isbf_v2.careers_validation")))
      );
    }
    return next(...args);
  });
  api.onAppEvent("composer:category-changed", (model) => {
    if (isCareersCategory(model)) {
      if (model.creatingTopic && isUntitledTopicTitle(model.title)) {
        model.setProperties({ title: "", isbf_optional_title: null });
      }
      restoreCareers(model);
    } else if (CAREERS_FIELDS.some((field) => model[field] != null)) {
      CAREERS_FIELDS.forEach((field) => model.set(field, null));
      if (isQuickPost(model)) {
        prepareOptionalTopicTitle(model);
      }
    }
  });
  api.onAppEvent("composer:edited-post", () => {
    const model = api.container.lookup("service:composer").model;
    const id = Number(model?.post?.id);
    if (isCareersComposer(model) && Number.isSafeInteger(id) && id > 0) {
      invalidateCookedPost(id, false);
    }
  });
  api.renderInOutlet("after-title-and-category", ISBFCareersComposer);
  api.renderInOutlet("after-title-and-category", ISBFCareersHome);
  api.customizeComposerText({
    titlePlaceholder: (model) =>
      isCareersComposer(model) ? themePrefix("isbf_v2.careers_name") : null,
  });
  api.registerValueTransformer(
    "composer-editor-reply-placeholder",
    ({ value, context }) =>
      isCareersComposer(context?.model?.model)
        ? themePrefix("isbf_v2.careers_description")
        : value
  );
  api.renderAfterWrapperOutlet("post-metadata", ISBFCareersSalary);
});
