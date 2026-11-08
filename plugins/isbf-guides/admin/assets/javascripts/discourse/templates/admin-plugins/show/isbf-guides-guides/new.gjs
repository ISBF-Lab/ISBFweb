import routeTemplate from "ember-route-template";
import IsbfGuidesEditor from "../../../../components/isbf-guides-editor";

export default routeTemplate(
  <template>
    <div class="admin-config-page__main-area"><IsbfGuidesEditor
        @guide={{@model.guide}}
      /></div>
  </template>
);
