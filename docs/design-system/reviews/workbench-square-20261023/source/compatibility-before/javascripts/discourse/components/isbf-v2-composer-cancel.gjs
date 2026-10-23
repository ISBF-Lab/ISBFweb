import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { isCareersComposer } from "../lib/careers";
import { isMarketplaceComposer } from "../lib/marketplace";
import { isQuickPost } from "../lib/quick-post-scope";
import { isTeamupComposer } from "../lib/teamup";

export default class ISBFV2ComposerCancel extends Component {
  @service composer;

  get visible() {
    const model = this.args.outletArgs?.model;
    return (
      isQuickPost(model) ||
      isMarketplaceComposer(model) ||
      isCareersComposer(model) ||
      isTeamupComposer(model)
    );
  }

  @action
  close(event) {
    this.composer.saveAndClose(event);
  }

  <template>
    {{#if this.visible}}
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
