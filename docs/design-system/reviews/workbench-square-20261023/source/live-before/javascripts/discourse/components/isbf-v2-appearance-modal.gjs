import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class ISBFV2AppearanceModal extends Component {
  @service dialog;
  @service interfaceColor;

  get title() {
    return i18n(themePrefix("isbf_v2.appearance"));
  }

  get options() {
    const currentMode = this.interfaceColor.colorMode || "auto";
    return [
      { mode: "light", icon: "sun" },
      { mode: "dark", icon: "moon" },
      { mode: "auto", icon: "circle-half-stroke" },
    ].map((option) => ({
      ...option,
      label: i18n(themePrefix(`isbf_v2.appearance_${option.mode}`)),
      selected: currentMode === option.mode,
    }));
  }

  @action
  async selectMode(mode) {
    if (!["light", "dark", "auto"].includes(mode)) {
      return;
    }
    if (!this.interfaceColor.selectorAvailable) {
      await this.dialog.alert(
        i18n(themePrefix("isbf_v2.appearance_unavailable")),
      );
      return;
    }
    if (mode === "light") {
      this.interfaceColor.forceLightMode();
    } else if (mode === "dark") {
      this.interfaceColor.forceDarkMode();
    } else {
      this.interfaceColor.useAutoMode();
    }
    this.args.closeModal();
  }

  <template>
    <DModal
      class="isbf-v2-appearance-modal"
      @closeModal={{@closeModal}}
      @title={{this.title}}
    >
      <:body>
        <div class="isbf-v2-appearance-modal__options">
          {{#each this.options key="mode" as |option|}}
            <DButton
              aria-pressed={{option.selected}}
              class="btn-flat isbf-v2-appearance-modal__option"
              @action={{fn this.selectMode option.mode}}
            >
              {{dIcon option.icon}}
              <span>{{option.label}}</span>
              <span
                aria-hidden="true"
                class="isbf-v2-appearance-modal__selected"
              >
                {{#if option.selected}}{{dIcon "check"}}{{/if}}
              </span>
            </DButton>
          {{/each}}
        </div>
      </:body>
    </DModal>
  </template>
}
