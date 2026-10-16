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

export default class ISBFNotificationEntry extends Component {
  @service siteSettings;

  get useNativeSummary() {
    return (
      this.args.standalone ||
      ![
        "liked",
        "reaction",
        "replied",
        "mentioned",
        "group_mentioned",
      ].includes(this.args.entry.action)
    );
  }

  get displayName() {
    const actor = this.args.entry.actor;
    if (!actor) {
      return null;
    }
    return displayIdentity({
      name: this.siteSettings.enable_names ? actor.name : null,
      username: actor.username,
    });
  }

  @action
  open(event) {
    this.args.entry.item.onClick({ event });
  }

  <template>
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
  </template>
}
