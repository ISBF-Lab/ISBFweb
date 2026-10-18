import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import templateOnly from "@ember/component/template-only";
export default setComponentTemplate(createTemplateFactory(
/*
  {{#if @unread}}
  <span aria-hidden="true" class="isbf-notification-unread"></span>
  <span class="sr-only">{{i18n
      (themePrefix "isbf_v2.notifications_unread")
    }}</span>
{{/if}}
*/
{
  "id": null,
  "block": "[[[41,[30,1],[[[1,\"  \"],[10,1],[14,\"aria-hidden\",\"true\"],[14,0,\"isbf-notification-unread\"],[12],[13],[1,\"\\n  \"],[10,1],[14,0,\"sr-only\"],[12],[1,[28,[32,0],[[28,[32,1],[\"isbf_v2.notifications_unread\"],null]],null]],[13],[1,\"\\n\"]],[]],null]],[\"@unread\"],[\"if\"]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    i18n,
    themePrefix
  }),
  "isStrictMode": true
}), templateOnly());