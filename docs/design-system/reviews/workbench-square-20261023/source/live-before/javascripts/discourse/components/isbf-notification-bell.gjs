import Component from "@glimmer/component";
import { service } from "@ember/service";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";

export default class ISBFNotificationBell extends Component {
  @service isbfNotifications;

  <template>
    <span aria-hidden="true" class="isbf-notification-bell" ...attributes>
      {{dIcon "bell"}}
      {{#if this.isbfNotifications.unreadCount}}
        <span
          class={{dConcatClass
            "isbf-notification-bell__badge"
            (if this.isbfNotifications.dotStyle "--dot")
          }}
        >{{#unless
            this.isbfNotifications.dotStyle
          }}{{this.isbfNotifications.displayCount}}{{/unless}}</span>
      {{/if}}
    </span>
  </template>
}
