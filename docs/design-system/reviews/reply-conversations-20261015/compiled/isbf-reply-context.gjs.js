import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import PostCookedHtml from "discourse/components/post/cooked-html";
import { ajax } from "discourse/lib/ajax";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import { i18n } from "discourse-i18n";
import { displayIdentity } from "../lib/user-display";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFReplyContext extends Component {
  static {
    g(this.prototype, "a11y", [service]);
  }
  #a11y = (i(this, "a11y"), void 0);
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  static {
    g(this.prototype, "store", [service]);
  }
  #store = (i(this, "store"), void 0);
  static {
    g(this.prototype, "expanded", [tracked], function () {
      return false;
    });
  }
  #expanded = (i(this, "expanded"), void 0);
  static {
    g(this.prototype, "loading", [tracked], function () {
      return false;
    });
  }
  #loading = (i(this, "loading"), void 0);
  static {
    g(this.prototype, "parent", [tracked], function () {
      return null;
    });
  }
  #parent = (i(this, "parent"), void 0);
  static {
    g(this.prototype, "unavailable", [tracked], function () {
      return false;
    });
  }
  #unavailable = (i(this, "unavailable"), void 0);
  get label() {
    const user = this.args.post.reply_to_user;
    const identity = displayIdentity({
      ...user,
      name: this.siteSettings.enable_names ? user?.name : null
    });
    return i18n(themePrefix("isbf_v2.reply_conversations.reply_to"), {
      name: identity || i18n(themePrefix("isbf_v2.reply_conversations.original_post")),
      number: this.args.post.reply_to_post_number
    });
  }
  get parentUrl() {
    return getURL(`${this.args.post.topic.url}/${this.args.post.reply_to_post_number}`);
  }
  async toggle() {
    if (this.loading) {
      return;
    }
    this.expanded = !this.expanded;
    if (!this.expanded || this.parent) {
      return;
    }
    this.loading = true;
    this.unavailable = false;
    const post = this.args.post;
    try {
      const data = await ajax(`/posts/by_number/${post.topic.id}/${post.reply_to_post_number}.json`);
      if (this.isDestroying || this.args.post !== post) {
        return;
      }
      if (data.deleted_at || data.deleted_post_placeholder || data.cooked_hidden || !data.cooked) {
        this.unavailable = true;
      } else {
        this.parent = this.store.createRecord("post", {
          ...data,
          topic: post.topic
        });
        this.a11y.announce(i18n(themePrefix("isbf_v2.reply_conversations.context_loaded")), "polite");
      }
    } catch {
      if (!this.isDestroying && this.args.post === post) {
        this.unavailable = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }
  static {
    n(this.prototype, "toggle", [action]);
  }
  retry() {
    this.expanded = false;
    return this.toggle();
  }
  static {
    n(this.prototype, "retry", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if @post.reply_to_post_number}}
      <div class="isbf-reply-context" ...attributes>
        <DButton
          class="btn-flat isbf-reply-context__toggle"
          @action={{this.toggle}}
          @ariaExpanded={{this.expanded}}
          @translatedLabel={{this.label}}
        />
        {{#if this.expanded}}
          <div class="isbf-reply-context__preview">
            <DConditionalLoadingSpinner @condition={{this.loading}}>
              {{#if this.parent}}
                <PostCookedHtml @post={{this.parent}} />
                <a
                  class="isbf-reply-context__link"
                  href={{this.parentUrl}}
                >{{i18n
                    (themePrefix "isbf_v2.reply_conversations.go_to_original")
                  }}</a>
              {{else if this.unavailable}}
                <p>{{i18n
                    (themePrefix
                      "isbf_v2.reply_conversations.context_unavailable"
                    )
                  }}</p>
                <DButton
                  class="btn-flat"
                  @action={{this.retry}}
                  @label="retry"
                />
              {{/if}}
            </DConditionalLoadingSpinner>
          </div>
        {{/if}}
      </div>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,1,[\"reply_to_post_number\"]],[[[1,\"  \"],[11,0],[24,0,\"isbf-reply-context\"],[17,2],[12],[1,\"\\n    \"],[8,[32,0],[[24,0,\"btn-flat isbf-reply-context__toggle\"]],[[\"@action\",\"@ariaExpanded\",\"@translatedLabel\"],[[30,0,[\"toggle\"]],[30,0,[\"expanded\"]],[30,0,[\"label\"]]]],null],[1,\"\\n\"],[41,[30,0,[\"expanded\"]],[[[1,\"      \"],[10,0],[14,0,\"isbf-reply-context__preview\"],[12],[1,\"\\n        \"],[8,[32,1],null,[[\"@condition\"],[[30,0,[\"loading\"]]]],[[\"default\"],[[[[1,\"\\n\"],[41,[30,0,[\"parent\"]],[[[1,\"            \"],[8,[32,2],null,[[\"@post\"],[[30,0,[\"parent\"]]]],null],[1,\"\\n            \"],[10,3],[14,0,\"isbf-reply-context__link\"],[15,6,[30,0,[\"parentUrl\"]]],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.reply_conversations.go_to_original\"],null]],null]],[13],[1,\"\\n\"]],[]],[[[41,[30,0,[\"unavailable\"]],[[[1,\"            \"],[10,2],[12],[1,[28,[32,3],[[28,[32,4],[\"isbf_v2.reply_conversations.context_unavailable\"],null]],null]],[13],[1,\"\\n            \"],[8,[32,0],[[24,0,\"btn-flat\"]],[[\"@action\",\"@label\"],[[30,0,[\"retry\"]],\"retry\"]],null],[1,\"\\n          \"]],[]],null]],[]]],[1,\"        \"]],[]]]]],[1,\"\\n      \"],[13],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],null]],[\"@post\",\"&attrs\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DButton,
        DConditionalLoadingSpinner,
        PostCookedHtml,
        i18n,
        themePrefix
      }),
      "isStrictMode": true
    }), this);
  }
}