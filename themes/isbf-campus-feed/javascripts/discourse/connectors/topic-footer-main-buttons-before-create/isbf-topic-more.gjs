import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DMenu from "discourse/float-kit/components/d-menu";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";

export default class ISBFTopicMore extends Component {
  @service site;

  get secondaryActions() {
    return (this.args.outletArgs.buttons ?? []).filter(
      (button) => button.id === "flag" || button.id === "defer"
    );
  }

  get showMenu() {
    return (
      this.site.desktopView &&
      !this.args.outletArgs.topic?.is_nested_view &&
      this.secondaryActions.length > 0
    );
  }

  @action
  async selectAction(button, menu) {
    await menu.close();
    return button.action();
  }

  <template>
    {{#if this.showMenu}}
      <DMenu
        class="isbf-v2-topic-more"
        @icon="ellipsis"
        @identifier="isbf-v2-topic-more"
        @label={{i18n "more"}}
        @modalForMobile={{true}}
        @triggerClass="btn-default topic-footer-button"
      >
        <:content as |menu|>
          <DDropdownMenu as |dropdown|>
            {{#each this.secondaryActions key="id" as |button|}}
              <dropdown.item>
                <DButton
                  @action={{fn this.selectAction button menu}}
                  @disabled={{button.disabled}}
                  @icon={{button.icon}}
                  @translatedLabel={{button.label}}
                  @translatedTitle={{button.title}}
                />
              </dropdown.item>
            {{/each}}
          </DDropdownMenu>
        </:content>
      </DMenu>
    {{/if}}
  </template>
}
