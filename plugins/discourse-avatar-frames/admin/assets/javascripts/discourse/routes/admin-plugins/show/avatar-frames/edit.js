import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AvatarFramesEditRoute extends DiscourseRoute {
  async model({ id }) {
    return (await ajax(`/avatar-frames/admin/frames/${id}`)).frame;
  }
}
