import Component from "@glimmer/component";
import { service } from "@ember/service";
import DUserLink from "discourse/ui-kit/d-user-link";
import { postCardTitle } from "../lib/post-card-helpers";
import { isConversationPost, isFeedStylePost } from "../lib/topic-card-scope";
import ISBFReplyContext from "./isbf-reply-context";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFTopicMetadata extends Component {
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  get enabled() {
    return isFeedStylePost(this.args.outletArgs.post, this.router.currentURL) || this.conversation;
  }
  get conversation() {
    return isConversationPost(this.args.outletArgs.post, this.router.currentURL, this.siteSettings);
  }
  get title() {
    const post = this.args.outletArgs.post;
    return post.post_number === 1 ? postCardTitle(post.topic.title, post.cooked) : null;
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
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
      {{#if this.conversation}}
        <ISBFReplyContext @post={{@outletArgs.post}} />
      {{/if}}
      {{#if this.title}}
        <h1
          class="isbf-feed-card__title isbf-topic-card__title"
        >{{this.title}}</h1>
      {{/if}}
    {{else}}
      {{yield}}
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[10,0],[14,0,\"isbf-post-card-header\"],[12],[1,\"\\n    \"],[18,2,null],[1,\"\\n    \"],[8,[32,0],[[24,0,\"isbf-feed-card__username\"]],[[\"@user\"],[[30,1,[\"post\",\"user\"]]]],[[\"default\"],[[[[1,\"\\n      @\"],[1,[30,1,[\"post\",\"username\"]]],[1,\"\\n    \"]],[]]]]],[1,\"\\n  \"],[13],[1,\"\\n\"],[41,[30,0,[\"conversation\"]],[[[1,\"    \"],[8,[32,1],null,[[\"@post\"],[[30,1,[\"post\"]]]],null],[1,\"\\n\"]],[]],null],[41,[30,0,[\"title\"]],[[[1,\"    \"],[10,\"h1\"],[14,0,\"isbf-feed-card__title isbf-topic-card__title\"],[12],[1,[30,0,[\"title\"]]],[13],[1,\"\\n\"]],[]],null]],[]],[[[1,\"  \"],[18,2,null],[1,\"\\n\"]],[]]]],[\"@outletArgs\",\"&default\"],[\"if\",\"yield\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DUserLink,
        ISBFReplyContext
      }),
      "isStrictMode": true
    }), this);
  }
}