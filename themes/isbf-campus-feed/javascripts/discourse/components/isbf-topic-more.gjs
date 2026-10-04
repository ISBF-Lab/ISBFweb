import Component from "@glimmer/component";
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
import { secondaryMenuFor } from "../lib/topic-card-scope";
import ISBFTopicInfo from "./isbf-topic-info";

export default class ISBFTopicMore extends Component {
  static shouldRender() {
    return true;
  }

  static extraControls() {
    return true;
  }

  @service modal;

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

  get isFirstPost() {
    return this.args.post.post_number === 1;
  }

  @action
  async showTopicInfo(menu) {
    await menu.close();
    this.modal.show(ISBFTopicInfo, { model: this.args.post.topic });
  }

  <template>
    <div class="isbf-topic-card__more-menu" ...attributes>
      <DMenu
        @ariaLabel={{i18n "more"}}
        @icon="ellipsis"
        @identifier={{this.identifier}}
        @modalForMobile={{true}}
        @title={{i18n "more"}}
        @triggerClass="btn-flat isbf-topic-card__more show-more-actions"
      >
        <:content as |menu|>
          <DDropdownMenu as |dropdown|>
            {{#each this.buttons key="key" as |button|}}
              <dropdown.item>
                <PostMenuButtonWrapper
                  @buttonActions={{@buttonActions}}
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
