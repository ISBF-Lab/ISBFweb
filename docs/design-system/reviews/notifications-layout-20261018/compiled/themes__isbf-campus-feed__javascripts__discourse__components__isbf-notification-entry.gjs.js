import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import MenuItem from "discourse/components/user-menu/menu-item";
import DRelativeDate from "discourse/ui-kit/d-relative-date";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { displayIdentity } from "../lib/user-display";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFNotificationEntry extends Component {
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  get useNativeSummary() {
    return this.args.standalone || !["liked", "reaction", "replied", "mentioned", "group_mentioned"].includes(this.args.entry.action);
  }
  get displayName() {
    const actor = this.args.entry.actor;
    if (!actor) {
      return null;
    }
    return displayIdentity({
      name: this.siteSettings.enable_names ? actor.name : null,
      username: actor.username
    });
  }
  open(event) {
    this.args.entry.item.onClick({
      event
    });
  }
  static {
    n(this.prototype, "open", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class={{if
        @entry.notification.read
        "isbf-notification-entry"
        "isbf-notification-entry is-unread"
      }}
    >
      {{#if @entry.actor}}
        <span class="isbf-notification-entry__avatar">{{dAvatar
            @entry.actor
            imageSize="medium"
          }}</span>
      {{else}}
        <span
          aria-hidden="true"
          class="isbf-notification-entry__avatar isbf-notification-entry__system"
        >{{dIcon @entry.item.icon}}</span>
      {{/if}}
      <div class="isbf-notification-entry__content">
        {{#unless @entry.notification.read}}<span class="sr-only">{{i18n
              (themePrefix "isbf_v2.notifications_unread")
            }}</span>{{/unless}}
        {{#if this.useNativeSummary}}
          <ul class="isbf-notification-entry__native"><MenuItem
              @item={{@entry.item}}
            /></ul>
        {{else}}
          <a
            class="isbf-notification-entry__link"
            href={{@entry.item.linkHref}}
            title={{@entry.item.linkTitle}}
            {{on "click" this.open}}
          >
            {{#if @entry.actor}}<span
                class="isbf-notification-entry__name"
              >{{this.displayName}}</span>
            {{/if}}
            <span>{{@entry.actionLabel}}</span>
          </a>
        {{/if}}
        <span class="isbf-notification-entry__time"><DRelativeDate
            @date={{@entry.created_at}}
          /></span>
      </div>
    </div>
    */
    {
      "id": null,
      "block": "[[[10,0],[15,0,[52,[30,1,[\"notification\",\"read\"]],\"isbf-notification-entry\",\"isbf-notification-entry is-unread\"]],[12],[1,\"\\n\"],[41,[30,1,[\"actor\"]],[[[1,\"    \"],[10,1],[14,0,\"isbf-notification-entry__avatar\"],[12],[1,[28,[32,0],[[30,1,[\"actor\"]]],[[\"imageSize\"],[\"medium\"]]]],[13],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-notification-entry__avatar isbf-notification-entry__system\"],[12],[1,[28,[32,1],[[30,1,[\"item\",\"icon\"]]],null]],[13],[1,\"\\n\"]],[]]],[1,\"  \"],[10,0],[14,0,\"isbf-notification-entry__content\"],[12],[1,\"\\n    \"],[41,[51,[30,1,[\"notification\",\"read\"]]],[[[10,1],[14,0,\"sr-only\"],[12],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.notifications_unread\"],null]],null]],[13]],[]],null],[1,\"\\n\"],[41,[30,0,[\"useNativeSummary\"]],[[[1,\"      \"],[10,\"ul\"],[14,0,\"isbf-notification-entry__native\"],[12],[8,[32,4],null,[[\"@item\"],[[30,1,[\"item\"]]]],null],[13],[1,\"\\n\"]],[]],[[[1,\"      \"],[11,3],[24,0,\"isbf-notification-entry__link\"],[16,6,[30,1,[\"item\",\"linkHref\"]]],[16,\"title\",[30,1,[\"item\",\"linkTitle\"]]],[4,[32,5],[\"click\",[30,0,[\"open\"]]],null],[12],[1,\"\\n        \"],[41,[30,1,[\"actor\"]],[[[10,1],[14,0,\"isbf-notification-entry__name\"],[12],[1,[30,0,[\"displayName\"]]],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[10,1],[12],[1,[30,1,[\"actionLabel\"]]],[13],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]]],[1,\"    \"],[10,1],[14,0,\"isbf-notification-entry__time\"],[12],[8,[32,6],null,[[\"@date\"],[[30,1,[\"created_at\"]]]],null],[13],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"@entry\"],[\"if\",\"unless\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dAvatar,
        dIcon,
        i18n,
        themePrefix,
        MenuItem,
        on,
        DRelativeDate
      }),
      "isStrictMode": true
    }), this);
  }
}