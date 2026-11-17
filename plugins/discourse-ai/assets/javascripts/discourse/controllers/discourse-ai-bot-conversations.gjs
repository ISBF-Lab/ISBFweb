import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { service } from "@ember/service";

export default class DiscourseAiBotConversations extends Controller {
  @service currentUser;
  @service siteSettings;

  @tracked llm = null;
  @tracked agent = null;
  @tracked conversation = null;
  queryParams = ["llm", "agent", "conversation"];

  get showForumWorkspace() {
    return (
      this.currentUser &&
      (this.siteSettings.ai_forum_assistant_enabled ||
        this.siteSettings.ai_forum_assistant_restrict_members)
    );
  }

  get showPreview() {
    return !this.currentUser;
  }
}
