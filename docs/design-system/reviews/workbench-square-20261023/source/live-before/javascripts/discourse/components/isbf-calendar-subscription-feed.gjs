import Component from "@glimmer/component";
import { themePrefix } from "virtual:theme";
import CalendarSubscriptionUrl from "discourse/components/calendar-subscription-url";
import { i18n } from "discourse-i18n";

export default class ISBFCalendarSubscriptionFeed extends Component {
  get url() {
    return this.args.outletArgs?.urls?.isbf_personal;
  }

  <template>
    {{#if this.url}}
      <CalendarSubscriptionUrl
        @description={{i18n
          (themePrefix "isbf_v2.calendar_subscription_description")
        }}
        @label={{i18n (themePrefix "isbf_v2.calendar_subscription_name")}}
        @url={{this.url}}
      />
    {{/if}}
  </template>
}
