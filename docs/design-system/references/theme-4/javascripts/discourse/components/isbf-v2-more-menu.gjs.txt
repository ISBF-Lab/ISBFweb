import Component from "@glimmer/component";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import { i18n } from "discourse-i18n";
import ISBFV2UtilityActions from "./isbf-v2-utility-actions";

export default class ISBFV2MoreMenu extends Component {
  fallbackPlacements = ["top-start", "top-end"];

  get contentClass() {
    return this.args.workbench
      ? "isbf-v2-more-menu isbf-v2-more-menu--workbench"
      : "isbf-v2-more-menu";
  }

  get identifier() {
    return this.args.workbench
      ? "isbf-v2-workbench-more"
      : "isbf-v2-sidebar-more";
  }

  get placement() {
    return this.args.workbench ? "top-end" : "top-start";
  }

  get triggerClass() {
    return this.args.workbench
      ? "btn-flat isbf-v2-workbench__more-trigger"
      : "btn-flat isbf-v2-side__more";
  }

  get visibilityOptimizer() {
    return this.args.workbench ? "none" : "flip";
  }

  <template>
    <DMenu
      @ariaLabel={{i18n (themePrefix "isbf_v2.sidebar_more")}}
      @contentClass={{this.contentClass}}
      @fallbackPlacements={{this.fallbackPlacements}}
      @icon="ellipsis"
      @identifier={{this.identifier}}
      @label={{i18n (themePrefix "isbf_v2.sidebar_more")}}
      @modalForMobile={{false}}
      @placement={{this.placement}}
      @title={{i18n (themePrefix "isbf_v2.sidebar_more")}}
      @triggerClass={{this.triggerClass}}
      @visibilityOptimizer={{this.visibilityOptimizer}}
    >
      <:content as |menu|>
        <ISBFV2UtilityActions @menu={{menu}} />
      </:content>
    </DMenu>
  </template>
}
