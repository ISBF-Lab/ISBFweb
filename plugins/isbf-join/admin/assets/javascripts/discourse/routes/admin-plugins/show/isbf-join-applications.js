import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class IsbfJoinApplicationsRoute extends Route {
  queryParams = { page: { refreshModel: true } };

  async model({ page }) {
    try {
      return await ajax("/isbf/join/admin/applications.json", {
        data: { page },
      });
    } catch {
      return { applications: [], load_error: true, page };
    }
  }
}
