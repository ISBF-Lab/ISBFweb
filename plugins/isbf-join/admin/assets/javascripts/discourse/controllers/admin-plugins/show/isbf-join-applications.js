import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";

export default class IsbfJoinApplicationsController extends Controller {
  @tracked page = 1;

  queryParams = ["page"];
}
