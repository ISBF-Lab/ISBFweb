import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AcademyStudentGroupBatchesRoute extends DiscourseRoute {
  @service currentUser;
  @service router;

  beforeModel() {
    if (!this.currentUser?.admin) {
      return this.router.replaceWith(
        "adminPlugins.show.academy-student-invites"
      );
    }
  }

  async model(params) {
    const base = "/academy-roles/admin/student-group-batches";
    const [options, history] = await Promise.all([
      ajax(`${base}/options.json`),
      ajax(`${base}.json`),
    ]);
    return {
      options,
      history,
      result: await ajax(`${base}/${params.batch_id}.json`),
    };
  }
}
