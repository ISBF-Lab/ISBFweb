import Component from "@glimmer/component";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { isTeamupComposer, TEAMUP_HOME_FIELD } from "../lib/teamup";
import ISBFHomeDisplayOption from "./isbf-home-display-option";

export default class ISBFTeamupComposer extends Component {
  get model() {
    return this.args.outletArgs?.model ?? this.args.outletArgs?.composer;
  }

  get visible() {
    return isTeamupComposer(this.model);
  }

  @action
  changeHome(event) {
    this.model.set(TEAMUP_HOME_FIELD, event.target.checked);
  }

  <template>
    {{#if this.visible}}
      <div class="isbf-teamup-composer">
        <ISBFHomeDisplayOption
          @checked={{this.model.isbf_teamup_home}}
          @label={{i18n (themePrefix "isbf_v2.marketplace_home")}}
          @onChange={{this.changeHome}}
        />
      </div>
    {{/if}}
  </template>
}
