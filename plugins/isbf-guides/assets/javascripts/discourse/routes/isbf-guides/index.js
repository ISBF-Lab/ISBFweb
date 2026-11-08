import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class IsbfGuidesIndexRoute extends DiscourseRoute {
  model() {
    return ajax("/guides.json");
  }
}
