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
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFActivityPreview extends Component {
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
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
      avatar_template: this.post.avatar_template
    };
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
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
              @postNumber={{this.post.post_number}}
              @topicId={{this.post.topic_id}}
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
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[10,\"article\"],[14,0,\"isbf-activity-preview\"],[12],[1,\"\\n    \"],[10,0],[14,0,\"isbf-activity-preview__header\"],[12],[1,\"\\n      \"],[8,[32,0],null,[[\"@user\"],[[30,0,[\"user\"]]]],[[\"default\"],[[[[1,\"\\n        \"],[1,[28,[32,1],[[30,0,[\"user\"]]],[[\"imageSize\",\"ignoreTitle\"],[\"large\",\"true\"]]]],[1,\"\\n      \"]],[]]]]],[1,\"\\n      \"],[10,0],[14,0,\"isbf-activity-preview__details\"],[12],[1,\"\\n\"],[41,[30,0,[\"title\"]],[[[1,\"          \"],[10,3],[14,0,\"isbf-activity-preview__title\"],[15,6,[30,0,[\"post\",\"postUrl\"]]],[12],[1,[28,[32,2],[[30,0,[\"title\"]]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"        \"],[10,0],[14,0,\"isbf-activity-preview__metadata\"],[12],[1,\"\\n\"],[41,[30,0,[\"post\",\"category\"]],[[[1,\"            \"],[10,1],[12],[1,[28,[32,3],[[30,0,[\"post\",\"category\"]]],[[\"styleType\"],[\"square\"]]]],[13],[1,\"\\n\"]],[]],null],[1,\"          \"],[10,1],[12],[1,[28,[32,4],[[30,0,[\"post\",\"created_at\"]]],[[\"leaveAgo\"],[\"true\"]]]],[13],[1,\"\\n        \"],[13],[1,\"\\n      \"],[13],[1,\"\\n      \"],[41,[30,0,[\"available\"]],[[[8,[32,5],null,[[\"@item\"],[[30,0,[\"post\"]]]],null]],[]],null],[1,\"\\n    \"],[13],[1,\"\\n\"],[41,[30,0,[\"available\"]],[[[41,[30,0,[\"post\",\"expandedExcerpt\"]],[[[1,\"        \"],[10,0],[14,0,\"excerpt isbf-activity-preview__body\"],[15,\"data-post-id\",[30,0,[\"post\",\"post_id\"]]],[15,\"data-topic-id\",[30,0,[\"post\",\"topic_id\"]]],[15,\"data-user-id\",[30,0,[\"post\",\"user_id\"]]],[12],[1,\"\\n          \"],[8,[32,6],null,[[\"@className\",\"@html\"],[\"cooked\",[28,[32,7],[[30,0,[\"post\",\"expandedExcerpt\"]]],null]]],null],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],[[[1,\"        \"],[8,[32,8],null,[[\"@excerpt\",\"@href\",\"@postId\",\"@postNumber\",\"@topicId\",\"@variant\"],[[30,0,[\"post\",\"excerpt\"]],[30,0,[\"post\",\"postUrl\"]],[30,0,[\"post\",\"post_id\"]],[30,0,[\"post\",\"post_number\"]],[30,0,[\"post\",\"topic_id\"]],\"activity\"]],null],[1,\"\\n\"]],[]]]],[]],[[[1,\"      \"],[8,[32,8],null,[[\"@disabled\",\"@href\",\"@variant\"],[true,[30,0,[\"post\",\"postUrl\"]],\"activity\"]],null],[1,\"\\n\"]],[]]],[1,\"  \"],[13],[1,\"\\n\"]],[]],null]],[],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DUserLink,
        dAvatar,
        dReplaceEmoji,
        dCategoryLink,
        dFormatDate,
        ExpandPost,
        DDecoratedHtml,
        trustHTML,
        ISBFPostPreview
      }),
      "isStrictMode": true
    }), this);
  }
}