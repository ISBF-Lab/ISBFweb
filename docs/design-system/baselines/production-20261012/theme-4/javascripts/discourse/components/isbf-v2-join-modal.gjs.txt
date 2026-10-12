import Component from "@glimmer/component";
import { settings, themePrefix } from "virtual:theme";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class ISBFV2JoinModal extends Component {
  get description() {
    return (
      settings.join_us_description?.trim() ||
      i18n(themePrefix("isbf_v2.join_us_pending"))
    );
  }

  <template>
    <DModal
      class="isbf-v2-join-modal"
      @closeModal={{@closeModal}}
      @title={{themePrefix "isbf_v2.join_us"}}
    >
      <:body>
        <p class="isbf-v2-join-modal__description">{{this.description}}</p>
      </:body>
    </DModal>
  </template>
}
