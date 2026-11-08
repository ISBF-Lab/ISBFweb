import Route from "@ember/routing/route";
import { i18n } from "discourse-i18n";

export default class IsbfGuidesAdminRoute extends Route {
  titleToken() {
    return i18n("isbf_guides.admin.title");
  }
}
