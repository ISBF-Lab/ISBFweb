import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class GuidesEditRoute extends Route {
  model({ guide_id }) {
    return ajax(`/isbf/guides/admin/guides/${guide_id}.json`);
  }
}
