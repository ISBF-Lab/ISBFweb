import Component from "@glimmer/component";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import ExpandPost from "discourse/components/expand-post";
import DDecoratedHtml from "discourse/ui-kit/d-decorated-html";
import DUserLink from "discourse/ui-kit/d-user-link";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dReplaceEmoji from "discourse/ui-kit/helpers/d-replace-emoji";
import { optionalTopicTitle } from "../lib/optional-topic-title";
import { isActivityPreview } from "../lib/post-preview";
import ISBFPostPreview from "./isbf-post-preview";

export default class ISBFActivityPreview extends Component {
  @service router;

  get available() {
    return !this.post.hidden && !this.post.deleted;
  }

  get enabled() {
    return isActivityPreview(this.post, this.router.currentURL);
  }

  get post() {
    return this.args.outletArgs.item;
  }

  get title() {
    return optionalTopicTitle(this.post.title);
  }

  get user() {
    return {
      id: this.post.user_id,
      name: this.post.name,
      username: this.post.username,
      avatar_template: this.post.avatar_template,
    };
  }

  <template>
    {{#if this.enabled}}
      <article class="isbf-activity-preview">
        <div class="isbf-activity-preview__header">
          <DUserLink @user={{this.user}}>
            {{dAvatar this.user imageSize="large" ignoreTitle="true"}}
          </DUserLink>
          <div class="isbf-activity-preview__details">
            {{#if this.title}}
              <a
                class="isbf-activity-preview__title"
                href={{this.post.postUrl}}
              >{{dReplaceEmoji this.title}}</a>
            {{/if}}
            <div class="isbf-activity-preview__metadata">
              {{#if this.post.category}}
                <span>{{dCategoryLink
                    this.post.category
                    styleType="square"
                  }}</span>
              {{/if}}
              <span>{{dFormatDate this.post.created_at leaveAgo="true"}}</span>
            </div>
          </div>
          {{#if this.available}}<ExpandPost @item={{this.post}} />{{/if}}
        </div>
        {{#if this.available}}
          {{#if this.post.expandedExcerpt}}
            <div
              class="excerpt isbf-activity-preview__body"
              data-post-id={{this.post.post_id}}
              data-topic-id={{this.post.topic_id}}
              data-user-id={{this.post.user_id}}
            >
              <DDecoratedHtml
                @className="cooked"
                @html={{trustHTML this.post.expandedExcerpt}}
              />
            </div>
          {{else}}
            <ISBFPostPreview
              @excerpt={{this.post.excerpt}}
              @href={{this.post.postUrl}}
              @postId={{this.post.post_id}}
              @variant="activity"
            />
          {{/if}}
        {{else}}
          <ISBFPostPreview
            @disabled={{true}}
            @href={{this.post.postUrl}}
            @variant="activity"
          />
        {{/if}}
      </article>
    {{/if}}
  </template>
}
