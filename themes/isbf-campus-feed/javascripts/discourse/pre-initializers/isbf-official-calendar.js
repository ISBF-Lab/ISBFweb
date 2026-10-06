import { withPluginApi } from "discourse/lib/plugin-api";
import Composer from "discourse/models/composer";
import {
  canonicalCalendarItems,
  isOfficialCalendarComposer,
  OFFICIAL_CALENDAR_FIELD,
} from "../lib/official-calendar";

export default {
  name: "isbf-official-calendar",
  after: "isbf-official-composer",
  before: "inject-discourse-objects",

  initialize() {
    withPluginApi((api) => {
      api.addModelField("composer", OFFICIAL_CALENDAR_FIELD, {
        defaultValue: null,
      });
      api.addModelGetter(
        "composer",
        "isbfOfficialCalendarPayload",
        function () {
          return isOfficialCalendarComposer(this, this.site)
            ? JSON.stringify(
                canonicalCalendarItems(this[OFFICIAL_CALENDAR_FIELD] ?? [])
              )
            : undefined;
        }
      );
      Composer.serializeOnCreate(
        OFFICIAL_CALENDAR_FIELD,
        "isbfOfficialCalendarPayload"
      );
      Composer.serializeOnUpdate(
        OFFICIAL_CALENDAR_FIELD,
        "isbfOfficialCalendarPayload"
      );
      Composer.serializeToDraft(
        OFFICIAL_CALENDAR_FIELD,
        OFFICIAL_CALENDAR_FIELD
      );

      const originalClearState = Composer.prototype.clearState;
      api.addModelMethod("composer", "clearState", function (...args) {
        const result = originalClearState.apply(this, args);
        this.set(OFFICIAL_CALENDAR_FIELD, null);
        return result;
      });

      const originalOpen = Composer.prototype.open;
      api.addModelMethod("composer", "open", function (...args) {
        return originalOpen.apply(this, args).then((result) => {
          if (
            isOfficialCalendarComposer(this, this.site) &&
            this[OFFICIAL_CALENDAR_FIELD] == null
          ) {
            this.set(
              OFFICIAL_CALENDAR_FIELD,
              canonicalCalendarItems(
                this.editingFirstPost
                  ? (this.post?.[OFFICIAL_CALENDAR_FIELD] ??
                      this.topic?.[OFFICIAL_CALENDAR_FIELD] ??
                      [])
                  : []
              )
            );
          }
          return result;
        });
      });
    });
  },
};
