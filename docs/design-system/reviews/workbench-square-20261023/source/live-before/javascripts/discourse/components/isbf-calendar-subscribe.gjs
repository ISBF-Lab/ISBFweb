import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import getURL from "discourse/lib/get-url";
import { headerOffset } from "discourse/lib/offset-calculator";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  calendarSubscriptionURL,
  PERSONAL_CALENDAR_FEED,
} from "../lib/calendar-subscription";
import ISBFCalendarProviderIcon from "./isbf-calendar-provider-icon";
import ISBFCalendarSubscription from "./isbf-calendar-subscription";

export default class ISBFCalendarSubscribe extends Component {
  @service currentUser;
  @service modal;
  @service site;

  @tracked opensUp = false;

  #cachedURL = null;
  #dialogModel = null;
  #opening = false;
  #ownerId = null;

  willDestroy() {
    this.#cachedURL = null;
    this.#ownerId = null;
    if (
      this.#dialogModel &&
      this.modal.activeModal?.opts?.model === this.#dialogModel
    ) {
      this.modal.close();
    }
    this.#dialogModel = null;
    super.willDestroy(...arguments);
  }

  get available() {
    this.#synchronizeOwner();
    return (
      this.currentUser &&
      this.site.isbf_calendar?.subscription_feed === PERSONAL_CALENDAR_FEED
    );
  }

  get providers() {
    return ["apple", "google", "outlook", "link"].map((id) => ({
      id,
      label: i18n(themePrefix(`isbf_v2.calendar_subscription_${id}`)),
    }));
  }

  @action
  registerMenu(menu) {
    // DMenu's argument allowlist omits this native positioning option.
    menu.options.allowedPlacements = ["top-end", "bottom-end"];
    Object.defineProperty(menu.options, "padding", {
      configurable: true,
      get: () => {
        const viewport = window.visualViewport;
        const viewportBottom = viewport
          ? viewport.offsetTop + viewport.height
          : window.innerHeight;
        const navigation = document
          .querySelector(".isbf-v2-mobile-nav")
          ?.getBoundingClientRect();
        return {
          top: Math.max(12, headerOffset()),
          right: 12,
          bottom: Math.max(
            12,
            navigation?.width > 0 && navigation.height > 0
              ? viewportBottom - navigation.top + 12
              : 12
          ),
          left: 12,
        };
      },
    });
  }

  @action
  positioned(content) {
    if (!this.isDestroying) {
      this.opensUp = content.dataset.placement.startsWith("top");
    }
  }

  @action
  async open(provider, menu) {
    if (
      !this.available ||
      this.#opening ||
      !this.providers.some((item) => item.id === provider)
    ) {
      return;
    }
    const userId = this.#synchronizeOwner();
    this.#opening = true;
    try {
      await menu.close();
      if (
        this.isDestroying ||
        !this.available ||
        this.#synchronizeOwner() !== userId
      ) {
        return;
      }
      this.#dialogModel = {
        userId,
        provider,
        initialUrl: this.#cachedURL,
        isOwnerCurrent: () =>
          !this.isDestroying && this.#synchronizeOwner() === userId,
        onURLChange: (url) => this.#rememberURL(userId, url),
      };
      this.modal.show(ISBFCalendarSubscription, {
        model: this.#dialogModel,
      });
    } finally {
      this.#opening = false;
    }
  }

  #rememberURL(userId, url) {
    if (this.isDestroying || this.#synchronizeOwner() !== userId) {
      return;
    }
    this.#cachedURL = calendarSubscriptionURL(
      url,
      window.location.origin,
      getURL("/isbf/api/calendar.ics")
    );
  }

  #synchronizeOwner() {
    const userId = this.currentUser?.id ?? null;
    if (userId !== this.#ownerId) {
      this.#cachedURL = null;
      this.#ownerId = userId;
    }
    return userId;
  }

  <template>
    {{#if this.available}}
      <DMenu
        @ariaLabel={{i18n (themePrefix "isbf_v2.calendar_subscribe")}}
        @contentClass="isbf-calendar-subscription-menu"
        @identifier="isbf-calendar-subscription"
        @matchTriggerWidth={{true}}
        @maxWidth="none"
        @modalForMobile={{false}}
        @onPositioned={{this.positioned}}
        @onRegisterApi={{this.registerMenu}}
        @placement="bottom-end"
        @triggerClass="btn-default isbf-calendar-subscribe"
        @visibilityOptimizer="autoPlacement"
      >
        <:trigger as |menu|>
          {{dIcon "calendar-days"}}
          <span>{{i18n (themePrefix "isbf_v2.calendar_subscribe")}}</span>
          {{dIcon
            (if
              menu.expanded
              (if this.opensUp "chevron-up" "chevron-down")
              "chevron-down"
            )
          }}
        </:trigger>
        <:content as |menu|>
          <DDropdownMenu as |dropdown|>
            {{#each this.providers key="id" as |provider|}}
              <dropdown.item>
                <DButton
                  class="btn-flat isbf-calendar-subscription-menu__item"
                  @action={{fn this.open provider.id menu}}
                >
                  <ISBFCalendarProviderIcon @provider={{provider.id}} />
                  <span>{{provider.label}}</span>
                </DButton>
              </dropdown.item>
            {{/each}}
          </DDropdownMenu>
        </:content>
      </DMenu>
    {{/if}}
  </template>
}
