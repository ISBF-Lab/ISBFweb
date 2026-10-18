import Component from "@glimmer/component";
import { service } from "@ember/service";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFNotificationBell extends Component {
  static {
    g(this.prototype, "isbfNotifications", [service]);
  }
  #isbfNotifications = (i(this, "isbfNotifications"), void 0);
  static {
    setComponentTemplate(createTemplateFactory(
    /*
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
    */
    {
      "id": null,
      "block": "[[[11,1],[24,\"aria-hidden\",\"true\"],[24,0,\"isbf-notification-bell\"],[17,1],[12],[1,\"\\n  \"],[1,[28,[32,0],[\"bell\"],null]],[1,\"\\n\"],[41,[30,0,[\"isbfNotifications\",\"unreadCount\"]],[[[1,\"    \"],[10,1],[15,0,[28,[32,1],[\"isbf-notification-bell__badge\",[52,[30,0,[\"isbfNotifications\",\"dotStyle\"]],\"--dot\"]],null]],[12],[41,[51,[30,0,[\"isbfNotifications\",\"dotStyle\"]]],[[[1,[30,0,[\"isbfNotifications\",\"displayCount\"]]]],[]],null],[13],[1,\"\\n\"]],[]],null],[13]],[\"&attrs\"],[\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dIcon,
        dConcatClass
      }),
      "isStrictMode": true
    }), this);
  }
}