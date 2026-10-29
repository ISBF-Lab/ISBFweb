import { and, not } from "discourse/truth-helpers";
import ISBFErrorPage from "../../components/isbf-error-page";

export default <template>
  {{#if
    (and
      @outletArgs.controller
      (not @outletArgs.controller.isNotFound)
      (not
        (and
          @outletArgs.controller.isForbidden @outletArgs.controller.errorHtml
        )
      )
    )
  }}
    <ISBFErrorPage @controller={{@outletArgs.controller}} />
  {{else}}
    {{yield}}
  {{/if}}
</template>
