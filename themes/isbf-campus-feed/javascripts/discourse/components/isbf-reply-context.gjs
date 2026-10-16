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

export default class ISBFReplyContext extends Component {
  @service a11y;
  @service siteSettings;
  @service store;

  @tracked expanded = false;
  @tracked loading = false;
  @tracked parent = null;
  @tracked unavailable = false;

  get label() {
    const user = this.args.post.reply_to_user;
    const identity = displayIdentity({
      ...user,
      name: this.siteSettings.enable_names ? user?.name : null,
    });
    return i18n(themePrefix("isbf_v2.reply_conversations.reply_to"), {
      name:
        identity ||
        i18n(themePrefix("isbf_v2.reply_conversations.original_post")),
      number: this.args.post.reply_to_post_number,
    });
  }

  get parentUrl() {
    return getURL(
      `${this.args.post.topic.url}/${this.args.post.reply_to_post_number}`
    );
  }

  @action
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
      const data = await ajax(
        `/posts/by_number/${post.topic.id}/${post.reply_to_post_number}.json`
      );
      if (this.isDestroying || this.args.post !== post) {
        return;
      }
      if (
        data.deleted_at ||
        data.deleted_post_placeholder ||
        data.cooked_hidden ||
        !data.cooked
      ) {
        this.unavailable = true;
      } else {
        this.parent = this.store.createRecord("post", {
          ...data,
          topic: post.topic,
        });
        this.a11y.announce(
          i18n(themePrefix("isbf_v2.reply_conversations.context_loaded")),
          "polite"
        );
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

  @action
  retry() {
    this.expanded = false;
    return this.toggle();
  }

  <template>
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
  </template>
}
