import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import PostMenuButtonConfig from "discourse/components/post/menu/button-config";
import PostMenuButtonWrapper from "discourse/components/post/menu/button-wrapper";
import DMenu from "discourse/float-kit/components/d-menu";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";
import { pinningMeta, saveHomePin } from "../lib/pinning";
import { secondaryMenuFor } from "../lib/topic-card-scope";
import ISBFHomePinDialog from "./isbf-home-pin-dialog";
import ISBFTopicInfo from "./isbf-topic-info";

export default class ISBFTopicMore extends Component {
  static shouldRender() {
    return true;
  }

  static extraControls() {
    return true;
  }

  @service appEvents;
  @service currentUser;
  @service dialog;
  @service modal;
  @service site;

  @tracked isPinning = false;
  @tracked pinNow = Date.now();

  #menu;
  #openingEdit = false;

  get buttonActions() {
    return { ...this.args.buttonActions, editPost: this.editPost };
  }

  get buttons() {
    return secondaryMenuFor(this.args.post)
      .map(
        ([key, Button]) =>
          new PostMenuButtonConfig({
            key,
            Component: Button,
            owner: getOwner(this),
            apiAdded: true,
            hidden: false,
            showLabel: true,
            position: {},
            replacementMap: new WeakMap(),
          })
      )
      .filter((button) =>
        button.shouldRender({
          post: this.args.post,
          state: this.args.state,
        })
      );
  }

  get identifier() {
    return "isbf-topic-card-more-" + this.args.post.id;
  }

  get canManageHomePin() {
    const config = this.site.isbf_pinning;
    return (
      this.isFirstPost &&
      !this.isDestroying &&
      this.currentUser?.admin === true &&
      config?.enabled === true &&
      config?.home_actions_enabled === true &&
      this.pinMetadata?.can_manage === true
    );
  }

  get isFirstPost() {
    return this.args.post.post_number === 1;
  }

  get pinMetadata() {
    return pinningMeta(this.args.post.topic, this.pinNow);
  }

  get showHomePin() {
    return this.pinMetadata?.active === true;
  }

  @action
  async cancelHomePin() {
    if (!this.canManageHomePin || this.isPinning || !this.showHomePin) {
      return;
    }
    this.isPinning = true;
    try {
      await this.#menu?.close();
      if (!this.canManageHomePin) {
        return;
      }
      await saveHomePin(this.args.post.topic, { enabled: false });
      this.onHomePinSaved();
    } catch (error) {
      await this.#showPinError(error);
    } finally {
      if (!this.isDestroying) {
        this.isPinning = false;
      }
    }
  }

  @action
  onHomePinSaved() {
    if (!this.isDestroying) {
      this.pinNow = Date.now();
      this.appEvents.trigger("isbf:home-pin-saved");
    }
  }

  @action
  async openHomePin() {
    if (!this.canManageHomePin || this.isPinning) {
      return;
    }
    this.isPinning = true;
    try {
      await this.#menu?.close();
      if (!this.canManageHomePin) {
        return;
      }
      this.pinNow = Date.now();
      this.modal.show(ISBFHomePinDialog, {
        model: { topic: this.args.post.topic, onSaved: this.onHomePinSaved },
      });
    } catch (error) {
      await this.#showPinError(error);
    } finally {
      if (!this.isDestroying) {
        this.isPinning = false;
      }
    }
  }

  @action
  registerMenu(menu) {
    this.#menu = menu;
  }

  @action
  async editPost(...args) {
    if (this.#openingEdit || this.isDestroying) {
      return;
    }
    this.#openingEdit = true;
    try {
      await this.#menu?.close();
      if (!this.isDestroying) {
        return await this.args.buttonActions.editPost(...args);
      }
    } finally {
      this.#openingEdit = false;
    }
  }

  @action
  async showTopicInfo(menu) {
    await menu.close();
    this.modal.show(ISBFTopicInfo, { model: this.args.post.topic });
  }

  async #showPinError(error) {
    if (!this.isDestroying) {
      await this.dialog.alert(
        error?.jqXHR?.responseJSON?.errors?.[0] ||
          error?.jqXHR?.responseJSON?.error ||
          i18n(themePrefix("isbf_v2.pin_error"))
      );
    }
  }

  <template>
    <div class="isbf-topic-card__more-menu" ...attributes>
      <DMenu
        @ariaLabel={{i18n "more"}}
        @icon="ellipsis"
        @identifier={{this.identifier}}
        @modalForMobile={{true}}
        @onRegisterApi={{this.registerMenu}}
        @title={{i18n "more"}}
        @triggerClass="btn-flat isbf-topic-card__more show-more-actions"
      >
        <:content as |menu|>
          <DDropdownMenu class="isbf-topic-card__menu" as |dropdown|>
            {{#if this.canManageHomePin}}
              <dropdown.item>
                <DButton
                  @action={{this.openHomePin}}
                  @disabled={{this.isPinning}}
                  @icon="thumbtack"
                  @translatedLabel={{i18n
                    (themePrefix
                      (if this.showHomePin "isbf_v2.pin_update" "isbf_v2.pin")
                    )
                  }}
                />
              </dropdown.item>
              {{#if this.showHomePin}}
                <dropdown.item>
                  <DButton
                    @action={{this.cancelHomePin}}
                    @disabled={{this.isPinning}}
                    @icon="thumbtack"
                    @translatedLabel={{i18n (themePrefix "isbf_v2.pin_cancel")}}
                  />
                </dropdown.item>
              {{/if}}
            {{/if}}
            {{#each this.buttons key="key" as |button|}}
              <dropdown.item>
                <PostMenuButtonWrapper
                  @buttonActions={{this.buttonActions}}
                  @buttonConfig={{button}}
                  @post={{@post}}
                  @state={{@state}}
                />
              </dropdown.item>
            {{/each}}
            {{#if this.isFirstPost}}
              <dropdown.item>
                <DButton
                  @action={{fn this.showTopicInfo menu}}
                  @icon="circle-info"
                  @translatedLabel={{i18n (themePrefix "isbf_v2.topic_info")}}
                />
              </dropdown.item>
            {{/if}}
          </DDropdownMenu>
        </:content>
      </DMenu>
    </div>
  </template>
}
