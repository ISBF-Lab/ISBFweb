import Route from "@ember/routing/route";

export default class GuidesNewRoute extends Route {
  model() {
    return { guide: null };
  }
}
