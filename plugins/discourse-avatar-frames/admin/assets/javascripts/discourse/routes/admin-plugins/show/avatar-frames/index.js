import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AvatarFramesIndexRoute extends DiscourseRoute {
  model() {
    return ajax("/avatar-frames/admin/frames");
  }
}
