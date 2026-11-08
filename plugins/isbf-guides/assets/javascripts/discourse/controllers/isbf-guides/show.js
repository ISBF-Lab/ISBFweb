import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";

export default class IsbfGuidesShowController extends Controller {
  @tracked preview = null;
  queryParams = ["preview"];
}
