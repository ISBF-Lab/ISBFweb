import { themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import getURL from "discourse/lib/get-url";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  api.renderInOutlet(
    "isbf-guides-index-header",
    <template>
      <a
        aria-label={{i18n (themePrefix "isbf_v2.learning_back")}}
        class="isbf-guides__workbench-back"
        href={{getURL "/isbf/workbench"}}
      >{{dIcon "arrow-left"}}</a>
      <h1>{{i18n "isbf_guides.title"}}</h1>
    </template>
  );
});
