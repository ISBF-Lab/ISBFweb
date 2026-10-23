import Component from "@glimmer/component";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import {
  officialActivityTimeLines,
  officialCalendarGroups,
  officialCalendarTitleDuplicatesTopic,
  officialTimeLabel,
} from "../lib/official-calendar";
import { officialConfig, officialLocationLabel } from "../lib/official-filters";

export default class ISBFOfficialActivitySummary extends Component {
  @service site;

  get groups() {
    return officialCalendarGroups(this.args.items).map((group) => ({
      ...group,
      showTitle: !officialCalendarTitleDuplicatesTopic(
        group.item,
        this.args.topicTitle
      ),
      timeLines: officialActivityTimeLines(group.item),
      locationLabel: officialLocationLabel(
        group.item.location,
        this.args.campusIds,
        officialConfig(this.site),
        i18n(themePrefix("isbf_v2.official_campus_separator"))
      ),
      timeLabel: group.isEvent ? null : officialTimeLabel(group.item),
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
              role="group"
            >
              {{#if group.showTitle}}
                <h3
                  class="isbf-official-activity-summary__title"
                >{{group.item.title}}</h3>
              {{/if}}
              <dl class="isbf-official-activity-summary__fields">
                <div class="isbf-official-activity-summary__field">
                  <dt>{{i18n
                      (themePrefix "isbf_v2.schedule_activity_time")
                    }}</dt>
                  <dd>
                    {{#each group.timeLines as |line|}}
                      <span
                        class="isbf-official-activity-summary__time-line"
                      >{{line}}</span>
                    {{/each}}
                  </dd>
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
                      group.locationLabel
                      group.locationLabel
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
              {{#if (has-block)}}
                <div class="isbf-official-activity-summary__actions">
                  {{yield group.item}}
                  {{#if group.deadline}}
                    {{yield group.deadline}}
                  {{/if}}
                </div>
              {{/if}}
            </section>
          {{else}}
            <section
              aria-label={{group.item.title}}
              class="isbf-official-activity-summary__deadline"
              data-schedule-id={{group.item.id}}
              role="group"
            >
              {{#if group.showTitle}}
                <strong>{{group.item.title}}</strong>
              {{/if}}
              <span>{{group.timeLabel}}</span>
              {{#if (has-block)}}
                <div class="isbf-official-activity-summary__actions">
                  {{yield group.item}}
                </div>
              {{/if}}
            </section>
          {{/if}}
        {{/each}}
      </div>
    {{/if}}
  </template>
}
