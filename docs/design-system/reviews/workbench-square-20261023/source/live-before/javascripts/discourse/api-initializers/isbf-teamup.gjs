import { themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import Composer from "discourse/models/composer";
import { i18n } from "discourse-i18n";
import ISBFTeamupComposer from "../components/isbf-teamup-composer";
import { extendComposerMethod } from "../lib/composer-model-extensions";
import { invalidateCookedPost } from "../lib/feed-post-loader";
import {
  isUntitledTopicTitle,
  prepareOptionalTopicTitle,
} from "../lib/optional-topic-title";
import { isQuickPost } from "../lib/quick-post-scope";
import {
  isTeamupCategory,
  isTeamupComposer,
  restoreTeamup,
  TEAMUP_HOME_FIELD,
  teamupPayload,
} from "../lib/teamup";

export default apiInitializer((api) => {
  Composer.serializeOnCreate(TEAMUP_HOME_FIELD, "isbfTeamupHomePayload");
  Composer.serializeOnUpdate(TEAMUP_HOME_FIELD, "isbfTeamupHomePayload");
  Composer.serializeToDraft(TEAMUP_HOME_FIELD, TEAMUP_HOME_FIELD);
  api.addModelGetter("composer", "isbfTeamupHomePayload", function () {
    return teamupPayload(this);
  });
  extendComposerMethod(api, "clearState", function (next, ...args) {
    const result = next(...args);
    this.set(TEAMUP_HOME_FIELD, null);
    return result;
  });
  extendComposerMethod(api, "open", function (next, options = {}) {
    return next(options).then((result) => {
      restoreTeamup(this, options);
      return result;
    });
  });
  extendComposerMethod(api, "save", function (next, ...args) {
    if (
      isTeamupComposer(this) &&
      (!this.title?.trim() ||
        isUntitledTopicTitle(this.title) ||
        !this.reply?.trim())
    ) {
      return Promise.resolve(
        this.dialog.alert(i18n(themePrefix("isbf_v2.teamup_validation"))),
      );
    }
    return next(...args);
  });
  api.onAppEvent("composer:category-changed", (model) => {
    if (isTeamupCategory(model)) {
      if (model.creatingTopic && isUntitledTopicTitle(model.title)) {
        model.setProperties({ title: "", isbf_optional_title: null });
      }
      restoreTeamup(model);
    } else if (
      model[TEAMUP_HOME_FIELD] !== null &&
      model[TEAMUP_HOME_FIELD] !== undefined
    ) {
      model.set(TEAMUP_HOME_FIELD, null);
      if (isQuickPost(model)) {
        prepareOptionalTopicTitle(model);
      }
    }
  });
  api.onAppEvent("composer:edited-post", () => {
    const model = api.container.lookup("service:composer").model;
    const id = Number(model?.post?.id);
    if (isTeamupComposer(model) && Number.isSafeInteger(id) && id > 0) {
      invalidateCookedPost(id, false);
    }
  });
  api.renderInOutlet("after-title-and-category", ISBFTeamupComposer);
});
