import { fn } from "@ember/helper";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default <template>
  <DModal
    class="isbf-resource-add-dialog"
    ...attributes
    @closeModal={{@onClose}}
    @title={{i18n (themePrefix "isbf_v2.resource_add")}}
  >
    <:body>
      <div class="isbf-resource-add-dialog__choices">
        <DButton
          class="btn-default isbf-resource-add-dialog__category"
          @action={{fn @onChoose "category"}}
          @translatedLabel={{i18n (themePrefix "isbf_v2.library_add_category")}}
        />
        <DButton
          class="btn-default isbf-resource-add-dialog__course"
          @action={{fn @onChoose "group"}}
          @disabled={{@courseDisabled}}
          @translatedLabel={{i18n (themePrefix "isbf_v2.learning_add_course")}}
        />
      </div>
    </:body>
  </DModal>
</template>
