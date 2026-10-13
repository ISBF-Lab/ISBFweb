import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AvatarFramesGrantsRoute extends DiscourseRoute {
  async model({ id }) {
    const base = `/avatar-frames/admin/frames/${id}`;
    const [frame, grants, imports] = await Promise.all([
      ajax(base),
      ajax(`${base}/grants`),
      ajax(`${base}/imports`),
    ]);
    return { frame: frame.frame, ...grants, imports: imports.imports };
  }
}
