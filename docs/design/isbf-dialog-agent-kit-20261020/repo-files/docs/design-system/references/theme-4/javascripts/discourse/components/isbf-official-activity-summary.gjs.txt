import Component from "@glimmer/component";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import {
  officialCalendarGroups,
  officialTimeLabel,
} from "../lib/official-calendar";

export default class ISBFOfficialActivitySummary extends Component {
  get groups() {
    return officialCalendarGroups(this.args.items).map((group) => ({
      ...group,
      timeLabel: officialTimeLabel(group.item),
      deadlineLabel: group.deadline
        ? officialTimeLabel(group.deadline)
        : i18n(themePrefix("isbf_v2.schedule_none")),
    }));
  }

  <template>
    {{#if this.groups.length}}
      <div class="isbf-official-activity-summary" ...attributes>
        {{#each this.groups as |group|}}
          {{#if group.isEvent}}
            <section
              aria-label={{group.item.title}}
              class="isbf-official-activity-summary__activity"
              data-schedule-id={{group.item.id}}
            >
              <h3
                class="isbf-official-activity-summary__title"
              >{{group.item.title}}</h3>
              <dl class="isbf-official-activity-summary__fields">
                <div class="isbf-official-activity-summary__field">
                  <dt>{{i18n
                      (themePrefix "isbf_v2.schedule_activity_time")
                    }}</dt>
                  <dd>{{group.timeLabel}}</dd>
                </div>
                <div class="isbf-official-activity-summary__field">
                  <dt>{{i18n
                      (themePrefix "isbf_v2.schedule_registration_deadline")
                    }}</dt>
                  <dd>{{group.deadlineLabel}}</dd>
                </div>
                <div class="isbf-official-activity-summary__field">
                  <dt>{{i18n (themePrefix "isbf_v2.schedule_location")}}</dt>
                  <dd>{{if
                      group.item.location
                      group.item.location
                      (i18n (themePrefix "isbf_v2.schedule_not_provided"))
                    }}</dd>
                </div>
                <div class="isbf-official-activity-summary__field">
                  <dt>{{i18n (themePrefix "isbf_v2.schedule_organizer")}}</dt>
                  <dd>{{if
                      group.item.organizer
                      group.item.organizer
                      (i18n (themePrefix "isbf_v2.schedule_not_provided"))
                    }}</dd>
                </div>
              </dl>
            </section>
          {{else}}
            <div
              class="isbf-official-activity-summary__deadline"
              data-schedule-id={{group.item.id}}
            >
              <strong>{{group.item.title}}</strong>
              <span>{{group.timeLabel}}</span>
            </div>
          {{/if}}
        {{/each}}
      </div>
    {{/if}}
  </template>
}
