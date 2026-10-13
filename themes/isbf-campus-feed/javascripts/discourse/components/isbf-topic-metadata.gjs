import Component from "@glimmer/component";
import { service } from "@ember/service";
import DUserLink from "discourse/ui-kit/d-user-link";
import { postCardTitle } from "../lib/post-card-helpers";
import { isFeedStylePost } from "../lib/topic-card-scope";

export default class ISBFTopicMetadata extends Component {
  @service router;

  get enabled() {
    return isFeedStylePost(this.args.outletArgs.post, this.router.currentURL);
  }

  get title() {
    const post = this.args.outletArgs.post;
    return post.post_number === 1
      ? postCardTitle(post.topic.title, post.cooked)
      : null;
  }

  <template>
    {{#if this.enabled}}
      <div class="isbf-post-card-header">
        {{yield}}
        <DUserLink
          class="isbf-feed-card__username"
          @user={{@outletArgs.post.user}}
        >
          @{{@outletArgs.post.username}}
        </DUserLink>
      </div>
      {{#if this.title}}
        <h1
          class="isbf-feed-card__title isbf-topic-card__title"
        >{{this.title}}</h1>
      {{/if}}
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
