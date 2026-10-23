import Component from "@glimmer/component";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { isFeedStylePost } from "../lib/topic-card-scope";

export default class ISBFSolvedSummary extends Component {
  @service router;
  @service siteSettings;

  get answer() {
    return this.args.post.topic?.accepted_answers?.[0];
  }

  get answerUrl() {
    const answer = this.answer;
    if (!answer) {
      return null;
    }
    if (typeof answer.url === "string" && answer.url.startsWith("/t/")) {
      return answer.url;
    }
    const topic = this.args.post.topic;
    return Number.isInteger(answer.post_number) && answer.post_number > 1
      ? topic.urlForPostNumber?.(answer.post_number) || null
      : null;
  }

  get enabled() {
    return Boolean(
      this.siteSettings.solved_enabled &&
      this.args.post.post_number === 1 &&
      isFeedStylePost(
        this.args.post,
        this.router.currentURL,
        this.args.decoratorState?.nestedReplyView
      ) &&
      this.answerUrl
    );
  }

  <template>
    {{#if this.enabled}}
      <a class="isbf-solved-summary" href={{this.answerUrl}}>
        {{dIcon "check"}}
        <span>{{i18n (themePrefix "isbf_v2.solved_view_answer")}}</span>
      </a>
    {{/if}}
  </template>
}
