import Component from "@glimmer/component";
import { service } from "@ember/service";
import ForumAssistantStatus from "./forum-assistant-status";

export default class ForumAssistantTopicStatus extends Component {
  @service forumAssistant;

  get topic() {
    return this.args.outletArgs?.model;
  }

  get visible() {
    return (
      this.topic?.is_bot_pm &&
      (this.forumAssistant.restricted || this.topic.is_forum_assistant)
    );
  }

  <template>
    {{#if this.visible}}
      <ForumAssistantStatus
        @readOnly={{this.topic.forum_assistant_read_only}}
      />
    {{/if}}
  </template>
}
