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
import { cardReplyCount } from "../lib/topic-card-scope";

export class ISBFTopicReply extends Component {
  get count() {
    return compactNumber(cardReplyCount(this.args.post));
  }

  <template>
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
    >{{this.count}}</DButton>
  </template>
}

export class ISBFTopicRepost extends Component {
  @service composer;
  @service currentUser;
  @service router;

  @tracked busy = false;

  @action
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
        title: post.topic.title,
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }

  <template>
    <DButton
      class="isbf-topic-card__repost"
      ...attributes
      @action={{this.repost}}
      @disabled={{this.busy}}
      @icon="retweet"
      @translatedAriaLabel={{i18n (themePrefix "isbf_v2.repost")}}
    />
  </template>
}

export const ISBFTopicLike = <template>
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
</template>;

export class ISBFTopicBookmark extends Component {
  @service currentUser;
  @service router;

  @tracked busy = false;

  get isFirstPost() {
    return this.args.post.post_number === 1;
  }

  get bookmarked() {
    return this.isFirstPost
      ? this.args.post.topic.bookmarked
      : this.args.post.bookmarked;
  }

  @action
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
        await ajax(`/t/${topic.id}/remove_bookmarks`, { type: "DELETE" });
        topic.set("bookmarked", false);
      } else {
        await ajax(`/t/${topic.id}/bookmark`, { type: "PUT" });
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

  <template>
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
  </template>
}
