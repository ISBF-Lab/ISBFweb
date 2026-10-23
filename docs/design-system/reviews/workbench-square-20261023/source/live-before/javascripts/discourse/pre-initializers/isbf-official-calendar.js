import { themePrefix } from "virtual:theme";
import { withPluginApi } from "discourse/lib/plugin-api";
import Composer from "discourse/models/composer";
import { i18n } from "discourse-i18n";
import { extendComposerMethod } from "../lib/composer-model-extensions";
import {
  calendarItemsWithTopicTitle,
  isOfficialCalendarComposer,
  OFFICIAL_CALENDAR_FIELD,
  officialCalendarNeedsTitle,
  officialCalendarTopicTitle,
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
          if (
            !isOfficialCalendarComposer(this, this.site) ||
            (officialCalendarNeedsTitle(this, this.site) &&
              !officialCalendarTopicTitle(this))
          ) {
            return;
          }
          return JSON.stringify(
            calendarItemsWithTopicTitle(
              this[OFFICIAL_CALENDAR_FIELD],
              officialCalendarTopicTitle(this),
            ),
          );
        },
      );
      Composer.serializeOnCreate(
        OFFICIAL_CALENDAR_FIELD,
        "isbfOfficialCalendarPayload",
      );
      Composer.serializeOnUpdate(
        OFFICIAL_CALENDAR_FIELD,
        "isbfOfficialCalendarPayload",
      );
      Composer.serializeToDraft(OFFICIAL_CALENDAR_FIELD);

      extendComposerMethod(api, "serializeDraftData", function (next, ...args) {
        const data = next(...args);
        if (isOfficialCalendarComposer(this, this.site)) {
          data[OFFICIAL_CALENDAR_FIELD] = calendarItemsWithTopicTitle(
            this[OFFICIAL_CALENDAR_FIELD],
            officialCalendarTopicTitle(this),
            { draft: true },
          );
        }
        return data;
      });

      extendComposerMethod(api, "save", function (next, ...args) {
        if (
          officialCalendarNeedsTitle(this, this.site) &&
          !officialCalendarTopicTitle(this)
        ) {
          return Promise.resolve(
            this.dialog.alert(
              i18n(themePrefix("isbf_v2.schedule_title_required")),
            ),
          ).then(() => {
            if (
              !this.isDestroying &&
              officialCalendarNeedsTitle(this, this.site) &&
              !officialCalendarTopicTitle(this)
            ) {
              const input =
                document.querySelector("#reply-control #isbf-optional-title") ??
                document.querySelector("#reply-control .title-input input");
              input?.focus();
            }
          });
        }
        return next(...args);
      });

      const originalClearState = Composer.prototype.clearState;
      api.addModelMethod("composer", "clearState", function (...args) {
        const result = originalClearState.apply(this, args);
        this.set(OFFICIAL_CALENDAR_FIELD, null);
        return result;
      });

      const originalOpen = Composer.prototype.open;
      api.addModelMethod("composer", "open", function (...args) {
        return originalOpen.apply(this, args).then((result) => {
          if (isOfficialCalendarComposer(this, this.site)) {
            const items =
              this[OFFICIAL_CALENDAR_FIELD] ??
              (this.editingFirstPost
                ? (this.post?.[OFFICIAL_CALENDAR_FIELD] ??
                  this.topic?.[OFFICIAL_CALENDAR_FIELD] ??
                  [])
                : []);
            this.set(
              OFFICIAL_CALENDAR_FIELD,
              calendarItemsWithTopicTitle(
                items,
                officialCalendarTopicTitle(this),
                {
                  draft: true,
                },
              ),
            );
          }
          return result;
        });
      });
    });
  },
};
