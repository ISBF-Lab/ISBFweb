import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class GuidesIndexRoute extends Route {
  queryParams = { page: { refreshModel: true } };

  model({ page }) {
    return ajax("/isbf/guides/admin/guides.json", { data: { page } });
  }
}
