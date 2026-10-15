import getURL from "discourse/lib/get-url";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default <template>
  <header class="isbf-resume-sharing-header" ...attributes>
    {{#if @backHref}}<a
        aria-label={{i18n "back_button"}}
        href={{getURL @backHref}}
      >{{dIcon "arrow-left"}}</a>{{/if}}
    <h1>{{@title}}</h1>
    {{yield}}
  </header>
</template>
