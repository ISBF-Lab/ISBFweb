import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import PostMenuBookmarkButton from "discourse/components/post/menu/buttons/bookmark";
import PostMenuLikeButton from "discourse/components/post/menu/buttons/like";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import { compactNumber, openQuotedRepost } from "../lib/post-card-helpers";
import { cardReplyCount, isConversationPost } from "../lib/topic-card-scope";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import templateOnly from "@ember/component/template-only";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export class ISBFTopicReply extends Component {
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  get conversation() {
    return isConversationPost(this.args.post, this.router.currentURL, this.siteSettings);
  }
  get count() {
    return compactNumber(cardReplyCount(this.args.post));
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DButton
      class="isbf-topic-card__reply reply"
      ...attributes
      @action={{@buttonActions.replyToPost}}
      @disabled={{if @state.currentUser (if @state.canCreatePost false true)}}
      @icon="comment"
      @translatedAriaLabel={{i18n
        "post.sr_reply_to"
        post_number=@post.post_number
        username=@post.username
      }}
    >{{#if this.conversation}}{{i18n
          "post.controls.reply"
        }}{{else}}{{this.count}}{{/if}}</DButton>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-topic-card__reply reply\"],[17,1]],[[\"@action\",\"@disabled\",\"@icon\",\"@translatedAriaLabel\"],[[30,2,[\"replyToPost\"]],[52,[30,3,[\"currentUser\"]],[52,[30,3,[\"canCreatePost\"]],false,true]],\"comment\",[28,[32,1],[\"post.sr_reply_to\"],[[\"post_number\",\"username\"],[[30,4,[\"post_number\"]],[30,4,[\"username\"]]]]]]],[[\"default\"],[[[[41,[30,0,[\"conversation\"]],[[[1,[28,[32,1],[\"post.controls.reply\"],null]]],[]],[[[1,[30,0,[\"count\"]]]],[]]]],[]]]]]],[\"&attrs\",\"@buttonActions\",\"@state\",\"@post\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton,
        i18n
      }),
      "isStrictMode": true
    }), this);
  }
}
export class ISBFTopicRepost extends Component {
  static {
    g(this.prototype, "composer", [service]);
  }
  #composer = (i(this, "composer"), void 0);
  static {
    g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (i(this, "currentUser"), void 0);
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
  static {
    g(this.prototype, "busy", [tracked], function () {
      return false;
    });
  }
  #busy = (i(this, "busy"), void 0);
  async repost() {
    if (this.busy) {
      return;
    }
    this.busy = true;
    const post = this.args.post;
    try {
      await openQuotedRepost({
        composer: this.composer,
        router: this.router,
        currentUser: this.currentUser,
        topicId: post.topic.id,
        postNumber: post.post_number,
        username: post.username,
        cookedHtml: post.cooked,
        title: post.topic.title
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }
  static {
    n(this.prototype, "repost", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DButton
      class="isbf-topic-card__repost"
      ...attributes
      @action={{this.repost}}
      @disabled={{this.busy}}
      @icon="retweet"
      @translatedAriaLabel={{i18n (themePrefix "isbf_v2.repost")}}
    />
    */
    {
      "id": null,
      "block": "[[[8,[32,0],[[24,0,\"isbf-topic-card__repost\"],[17,1]],[[\"@action\",\"@disabled\",\"@icon\",\"@translatedAriaLabel\"],[[30,0,[\"repost\"]],[30,0,[\"busy\"]],\"retweet\",[28,[32,1],[[28,[32,2],[\"isbf_v2.repost\"],null]],null]]],null]],[\"&attrs\"],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}
export const ISBFTopicLike = setComponentTemplate(createTemplateFactory(
/*
  <div class="isbf-topic-card__like" ...attributes>
  {{#if @post.showLike}}
    <PostMenuLikeButton
      @buttonActions={{@buttonActions}}
      @post={{@post}}
      @showLabel={{false}}
      @state={{@state}}
    />
  {{else if @post.likeCount}}
    <PostMenuLikeButton
      @buttonActions={{@buttonActions}}
      @post={{@post}}
      @showLabel={{false}}
      @state={{@state}}
    />
  {{else}}
    <DButton
      class="btn-flat"
      @disabled={{true}}
      @icon="heart"
      @title="post.controls.like"
    />
  {{/if}}
</div>
*/
{
  "id": null,
  "block": "[[[11,0],[24,0,\"isbf-topic-card__like\"],[17,1],[12],[1,\"\\n\"],[41,[30,2,[\"showLike\"]],[[[1,\"    \"],[8,[32,0],null,[[\"@buttonActions\",\"@post\",\"@showLabel\",\"@state\"],[[30,3],[30,2],false,[30,4]]],null],[1,\"\\n\"]],[]],[[[41,[30,2,[\"likeCount\"]],[[[1,\"    \"],[8,[32,0],null,[[\"@buttonActions\",\"@post\",\"@showLabel\",\"@state\"],[[30,3],[30,2],false,[30,4]]],null],[1,\"\\n\"]],[]],[[[1,\"    \"],[8,[32,1],[[24,0,\"btn-flat\"]],[[\"@disabled\",\"@icon\",\"@title\"],[true,\"heart\",\"post.controls.like\"]],null],[1,\"\\n  \"]],[]]]],[]]],[13]],[\"&attrs\",\"@post\",\"@buttonActions\",\"@state\"],[\"if\"]]",
  "moduleName": "(unknown template module)",
  "scope": () => ({
    PostMenuLikeButton,
    DButton
  }),
  "isStrictMode": true
}), templateOnly());
export class ISBFTopicBookmark extends Component {
  static {
    g(this.prototype, "currentUser", [service]);
  }
  #currentUser = (i(this, "currentUser"), void 0);
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
  static {
    g(this.prototype, "busy", [tracked], function () {
      return false;
    });
  }
  #busy = (i(this, "busy"), void 0);
  get isFirstPost() {
    return this.args.post.post_number === 1;
  }
  get bookmarked() {
    return this.isFirstPost ? this.args.post.topic.bookmarked : this.args.post.bookmarked;
  }
  async bookmark() {
    if (!this.currentUser) {
      return this.router.transitionTo("login");
    }
    if (this.busy || !this.args.post.canBookmark) {
      return;
    }
    this.busy = true;
    const topic = this.args.post.topic;
    try {
      if (topic.bookmarked) {
        await ajax(`/t/${topic.id}/remove_bookmarks`, {
          type: "DELETE"
        });
        topic.set("bookmarked", false);
      } else {
        await ajax(`/t/${topic.id}/bookmark`, {
          type: "PUT"
        });
        topic.set("bookmarked", true);
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }
  static {
    n(this.prototype, "bookmark", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class={{dConcatClass
        "isbf-topic-card__bookmark"
        (if this.bookmarked "bookmarked")
      }}
      ...attributes
    >
      {{#if this.isFirstPost}}
        <DButton
          class="btn-flat"
          @action={{this.bookmark}}
          @disabled={{this.busy}}
          @icon={{if this.bookmarked "bookmark" "far-bookmark"}}
          @translatedAriaLabel={{i18n (themePrefix "isbf_v2.bookmark_action")}}
        />
      {{else}}
        <PostMenuBookmarkButton
          @buttonActions={{@buttonActions}}
          @post={{@post}}
          @showLabel={{false}}
          @state={{@state}}
        />
      {{/if}}
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[16,0,[28,[32,0],[\"isbf-topic-card__bookmark\",[52,[30,0,[\"bookmarked\"]],\"bookmarked\"]],null]],[17,1],[12],[1,\"\\n\"],[41,[30,0,[\"isFirstPost\"]],[[[1,\"    \"],[8,[32,1],[[24,0,\"btn-flat\"]],[[\"@action\",\"@disabled\",\"@icon\",\"@translatedAriaLabel\"],[[30,0,[\"bookmark\"]],[30,0,[\"busy\"]],[52,[30,0,[\"bookmarked\"]],\"bookmark\",\"far-bookmark\"],[28,[32,2],[[28,[32,3],[\"isbf_v2.bookmark_action\"],null]],null]]],null],[1,\"\\n\"]],[]],[[[1,\"    \"],[8,[32,4],null,[[\"@buttonActions\",\"@post\",\"@showLabel\",\"@state\"],[[30,2],[30,3],false,[30,4]]],null],[1,\"\\n\"]],[]]],[13]],[\"&attrs\",\"@buttonActions\",\"@post\",\"@state\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        DButton,
        i18n,
        themePrefix,
        PostMenuBookmarkButton
      }),
      "isStrictMode": true
    }), this);
  }
}