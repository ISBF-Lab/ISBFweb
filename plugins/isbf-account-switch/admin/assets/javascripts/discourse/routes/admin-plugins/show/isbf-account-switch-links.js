import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class AdminPluginsShowIsbfAccountSwitchLinksRoute extends Route {
  model() {
    return ajax("/isbf/account-switch/admin/links");
  }
}
