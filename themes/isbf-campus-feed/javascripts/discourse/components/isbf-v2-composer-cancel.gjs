import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { isQuickPost } from "../lib/quick-post-scope";

export default class ISBFV2ComposerCancel extends Component {
  @service composer;

  get isQuickPost() {
    return isQuickPost(this.args.outletArgs?.model);
  }

  @action
  close(event) {
    this.composer.saveAndClose(event);
  }

  <template>
    {{#if this.isQuickPost}}
      <button
        class="isbf-v2-composer-cancel"
        type="button"
        {{on "click" this.close}}
      >
        {{i18n (themePrefix "isbf_v2.compose_cancel")}}
      </button>
    {{/if}}
  </template>
}
