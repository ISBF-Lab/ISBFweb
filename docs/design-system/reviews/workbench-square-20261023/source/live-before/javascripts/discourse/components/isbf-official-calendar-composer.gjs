import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import {
  canonicalCalendarItems,
  isOfficialCalendarComposer,
  OFFICIAL_CALENDAR_FIELD,
  officialCalendarTopicTitle,
} from "../lib/official-calendar";
import ISBFOfficialCalendarEditor from "./isbf-official-calendar-editor";

export default class ISBFOfficialCalendarComposer extends Component {
  @service modal;
  @service site;

  get visible() {
    return Boolean(
      this.site.isbf_calendar &&
      isOfficialCalendarComposer(this.args.model, this.site),
    );
  }

  get eventCount() {
    return this.items.filter((item) => item.schedule_kind === "event").length;
  }

  get deadlineCount() {
    return this.items.filter((item) => item.schedule_kind === "deadline")
      .length;
  }

  get items() {
    return canonicalCalendarItems(
      this.args.model[OFFICIAL_CALENDAR_FIELD] ?? [],
    );
  }

  get eventLabel() {
    return i18n(
      themePrefix(
        this.eventCount
          ? "isbf_v2.schedule_activity_count"
          : "isbf_v2.schedule_activity_time",
      ),
      { count: this.eventCount },
    );
  }

  get deadlineLabel() {
    return i18n(
      themePrefix(
        this.deadlineCount
          ? "isbf_v2.schedule_registration_count"
          : "isbf_v2.schedule_registration_deadline",
      ),
      { count: this.deadlineCount },
    );
  }

  @action
  edit(section) {
    const model = this.args.model;
    this.modal.show(ISBFOfficialCalendarEditor, {
      model: {
        section,
        items: model[OFFICIAL_CALENDAR_FIELD] ?? [],
        getTopicTitle: () => officialCalendarTopicTitle(model),
        onSave: (items) => {
          if (
            this.isDestroying ||
            model !== this.args.model ||
            !isOfficialCalendarComposer(model, this.site)
          ) {
            throw new Error("Official composer is no longer active");
          }
          model.set(OFFICIAL_CALENDAR_FIELD, items);
        },
      },
    });
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-official-calendar-composer">
        <DButton
          class="isbf-official-calendar-composer__event"
          @action={{fn this.edit "event"}}
          @icon={{if this.eventCount "pencil" "plus"}}
          @translatedLabel={{this.eventLabel}}
        />
        <DButton
          class="isbf-official-calendar-composer__deadline"
          @action={{fn this.edit "deadline"}}
          @icon={{if this.deadlineCount "pencil" "plus"}}
          @translatedLabel={{this.deadlineLabel}}
        />
      </div>
    {{/if}}
  </template>
}
