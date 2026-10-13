import { themePrefix } from "virtual:theme";
import { withPluginApi } from "discourse/lib/plugin-api";
import Composer from "discourse/models/composer";
import { i18n } from "discourse-i18n";
import {
  isOfficialComposer,
  OFFICIAL_FIELDS,
  officialConfig,
  officialPayload,
  officialSelectionsComplete,
  restoreOfficialSelections,
} from "../lib/official-filters";

export default {
  name: "isbf-official-composer",
  after: "isbf-composer-optional-title",
  before: "inject-discourse-objects",

  initialize() {
    withPluginApi((api) => {
      OFFICIAL_FIELDS.forEach((field, index) => {
        const property =
          index === 0
            ? "isbfOfficialCampusesPayload"
            : "isbfOfficialTypesPayload";

        api.addModelField("composer", field, { defaultValue: null });
        api.addModelGetter("composer", property, function () {
          return officialPayload(this, officialConfig(this.site), field);
        });
        Composer.serializeOnCreate(field, property);
        Composer.serializeOnUpdate(field, property);
        Composer.serializeToDraft(field, field);
      });

      const originalClearState = Composer.prototype.clearState;
      api.addModelMethod("composer", "clearState", function (...args) {
        const result = originalClearState.apply(this, args);
        this.setProperties({
          isbf_official_campuses: null,
          isbf_official_types: null,
        });
        return result;
      });

      const originalOpen = Composer.prototype.open;
      api.addModelMethod("composer", "open", function (...args) {
        return originalOpen.apply(this, args).then((result) => {
          restoreOfficialSelections(this, officialConfig(this.site));
          return result;
        });
      });

      const originalSave = Composer.prototype.save;
      api.addModelMethod("composer", "save", function (...args) {
        const config = officialConfig(this.site);
        if (
          isOfficialComposer(this, config) &&
          !officialSelectionsComplete(this, config)
        ) {
          return Promise.resolve(
            this.dialog.alert(i18n(themePrefix("isbf_v2.official_required")))
          );
        }
        return originalSave.apply(this, args);
      });
    });
  },
};
