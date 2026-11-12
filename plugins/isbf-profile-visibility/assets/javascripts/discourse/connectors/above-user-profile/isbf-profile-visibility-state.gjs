import Component from "@glimmer/component";
import bodyClass from "discourse/helpers/body-class";
import { hidesSection } from "../../lib/profile-visibility";

// The core navigation always renders the summary tab; the stylesheet hides it from this state.
export default class IsbfProfileVisibilityState extends Component {
  get summaryHidden() {
    return hidesSection(this.args.outletArgs.model, "summary");
  }

  <template>
    {{#if this.summaryHidden}}
      {{bodyClass "isbf-profile-summary-hidden"}}
    {{/if}}
  </template>
}
