import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class IsbfGuidesShowRoute extends DiscourseRoute {
  queryParams = { preview: { refreshModel: true } };

  async model({ slug, preview }) {
    return ajax(`/guides/${encodeURIComponent(slug)}.json`, {
      data: { preview },
    });
  }

  titleToken() {
    return this.currentModel?.guide?.title;
  }
}
