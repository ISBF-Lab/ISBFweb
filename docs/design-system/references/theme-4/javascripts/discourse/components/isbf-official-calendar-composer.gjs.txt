import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import {
  isOfficialCalendarComposer,
  OFFICIAL_CALENDAR_FIELD,
} from "../lib/official-calendar";
import ISBFOfficialCalendarEditor from "./isbf-official-calendar-editor";

export default class ISBFOfficialCalendarComposer extends Component {
  @service modal;
  @service site;

  get visible() {
    return Boolean(
      this.site.isbf_calendar &&
      isOfficialCalendarComposer(this.args.model, this.site)
    );
  }

  get countLabel() {
    return i18n(themePrefix("isbf_v2.schedule_item_count"), {
      count: this.args.model[OFFICIAL_CALENDAR_FIELD]?.length ?? 0,
    });
  }

  @action
  edit() {
    const model = this.args.model;
    this.modal.show(ISBFOfficialCalendarEditor, {
      model: {
        items: model[OFFICIAL_CALENDAR_FIELD] ?? [],
        onSave: (items) => model.set(OFFICIAL_CALENDAR_FIELD, items),
      },
    });
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-official-calendar-composer">
        <DButton
          @action={{this.edit}}
          @icon="calendar-days"
          @label={{themePrefix "isbf_v2.schedule_editor_title"}}
        />
        <span>{{this.countLabel}}</span>
      </div>
    {{/if}}
  </template>
}
