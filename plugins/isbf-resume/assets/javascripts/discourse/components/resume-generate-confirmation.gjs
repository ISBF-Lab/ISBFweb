import { fn, hash } from "@ember/helper";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default <template>
  <DModal
    class="isbf-resume-confirmation"
    ...attributes
    @closeModal={{@closeModal}}
    @title={{if
      @model.english
      (i18n "isbf_resume.english_confirmation_title")
      (i18n "isbf_resume.confirmation_title")
    }}
  >
    <:body>
      {{#if @model.english}}
        <p class="isbf-resume-confirmation__language">{{i18n
            "isbf_resume.english_notice"
          }}</p>
      {{/if}}
      <p>{{i18n "isbf_resume.generation_notice"}}</p>
      <p class="isbf-resume-confirmation__frequency">{{i18n
          "isbf_resume.frequency_notice"
        }}</p>
    </:body>
    <:footer>
      <DButton
        class="btn-primary"
        @action={{fn @closeModal (hash confirmed=true)}}
        @label="isbf_resume.confirm_generate"
      />
      <DButton
        class="btn-default"
        @action={{fn @closeModal null}}
        @label="isbf_resume.return_edit"
      />
    </:footer>
  </DModal>
</template>
