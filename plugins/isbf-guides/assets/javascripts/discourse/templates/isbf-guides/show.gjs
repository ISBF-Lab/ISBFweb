import routeTemplate from "ember-route-template";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import IsbfGuideContent from "../../components/isbf-guide-content";

export default routeTemplate(
  <template>
    <main class="isbf-guides isbf-v2-feature">
      <a class="isbf-guides__back" href="/guides">{{dIcon "arrow-left"}}{{i18n
          "isbf_guides.all_guides"
        }}</a>
      <IsbfGuideContent @guide={{@model.guide}} />
    </main>
  </template>
);
