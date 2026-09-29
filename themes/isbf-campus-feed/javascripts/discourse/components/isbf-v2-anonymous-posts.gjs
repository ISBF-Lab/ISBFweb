import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class ISBFV2AnonymousPosts extends Component {
  @tracked posts = [];
  @tracked nextBeforeId;
  @tracked loading = false;
  @tracked loaded = false;
  @tracked error = false;

  constructor() {
    super(...arguments);
    scheduleOnce("afterRender", this, this.loadMore);
  }

  get isEmpty() {
    return this.loaded && this.posts.length === 0;
  }

  get hasMore() {
    return Boolean(this.nextBeforeId);
  }

  @action
  async loadMore() {
    if (this.isDestroying || this.loading || (this.loaded && !this.hasMore)) {
      return;
    }

    this.loading = true;
    this.error = false;
    try {
      const response = await ajax("/isbf-anonymous/api/posts", {
        data: this.nextBeforeId ? { before_id: this.nextBeforeId } : {},
      });
      if (this.isDestroying) {
        return;
      }
      this.posts = [...this.posts, ...response.posts];
      this.nextBeforeId = response.next_before_id;
      this.loaded = true;
    } catch {
      if (!this.isDestroying) {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.loading = false;
      }
    }
  }

  <template>
    <main class="isbf-v2-feature isbf-v2-anonymous-posts">
      <h1 class="sr-only">{{i18n
          (themePrefix "isbf_v2.my_anonymous_posts")
        }}</h1>
      {{#each this.posts as |post|}}
        <article class="isbf-v2-anonymous-posts__item">
          <a href={{post.url}}>{{post.title}}</a>
          <p>{{post.excerpt}}</p>
        </article>
      {{/each}}
      {{#if this.error}}
        <p role="alert">{{i18n
            (themePrefix "isbf_v2.anonymous_posts_load_error")
          }}</p>
      {{else if this.isEmpty}}
        <p>{{i18n (themePrefix "isbf_v2.anonymous_posts_empty")}}</p>
      {{/if}}
      {{#if this.hasMore}}
        <DButton
          class="isbf-v2-anonymous-posts__more"
          @action={{this.loadMore}}
          @isLoading={{this.loading}}
          @label={{themePrefix "isbf_v2.load_more"}}
        />
      {{/if}}
    </main>
  </template>
}
