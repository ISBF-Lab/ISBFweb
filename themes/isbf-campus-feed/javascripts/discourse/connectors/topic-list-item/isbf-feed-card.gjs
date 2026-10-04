import Component from "@glimmer/component";
import { service } from "@ember/service";
import { settings } from "virtual:theme";
import ISBFV2FeedCard from "../../components/isbf-v2-feed-card";

export default class ISBFFeedCardConnector extends Component {
  @service router;

  get shouldRenderCard() {
    if (this.args.outletArgs.bulkSelectEnabled) {
      return false;
    }
    const path = (this.router.currentURL ?? "").split("?")[0];
    const officialPath = settings.official_path.split("/l/")[0];
    return (
      path === "/" ||
      path.startsWith("/latest") ||
      path === officialPath ||
      path.startsWith(`${officialPath}/`)
    );
  }

  <template>
    {{#if this.shouldRenderCard}}
      <td class="isbf-feed-card-cell" colspan="6"><ISBFV2FeedCard
          @navigateToTopic={{@outletArgs.navigateToTopic}}
          @topic={{@outletArgs.topic}}
        /></td>
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
