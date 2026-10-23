import { withPluginApi } from "discourse/lib/plugin-api";
import Composer from "discourse/models/composer";

export default {
  name: "isbf-composer-optional-title",
  before: "inject-discourse-objects",

  initialize() {
    withPluginApi((api) => {
      api.addModelField("composer", "isbf_optional_title", {
        defaultValue: null,
      });
      Composer.serializeToDraft("isbf_optional_title", "isbf_optional_title");

      const originalClearState = Composer.prototype.clearState;
      api.addModelMethod("composer", "clearState", function (...args) {
        const result = originalClearState.apply(this, args);
        this.set("isbf_optional_title", null);
        return result;
      });
    });
  },
};
