import Component from "@glimmer/component";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import { isTopTopicsPath } from "../lib/top-topics-scope";
import ISBFTopTopics from "./isbf-top-topics";

export default class ISBFTopTopicsArea extends Component {
  @service router;

  get discoveryController() {
    return getOwner(this).lookup("controller:discovery.top");
  }

  get shouldRender() {
    return (
      isTopTopicsPath(this.router.currentURL) &&
      this.args.outletArgs.model?.filterType === "top" &&
      !this.discoveryController.bulkSelectHelper?.bulkSelectEnabled
    );
  }

  <template>
    {{#if this.shouldRender}}
      <ISBFTopTopics
        @model={{@outletArgs.model.list}}
        @onPeriodChange={{this.discoveryController.changePeriod}}
      />
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
