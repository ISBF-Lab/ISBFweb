import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action, get } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import PostMenuBookmarkButton from "discourse/components/post/menu/buttons/bookmark";
import PostMenuLikeButton from "discourse/components/post/menu/buttons/like";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import PostActionPulse from "../lib/post-action-pulse";
import { openQuotedRepost } from "../lib/post-card-helpers";
import { cardReplyCount } from "../lib/topic-card-scope";
import postActionPulse from "../modifiers/post-action-pulse";
import ISBFPostActionCount from "./isbf-post-action-count";

export class ISBFTopicReply extends Component {
  pulse = new PostActionPulse();

  get count() {
    return cardReplyCount(this.args.post);
  }

  @action
  async reply() {
    try {
      return await this.args.buttonActions.replyToPost();
    } finally {
      this.pulse.settle("reply");
    }
  }

  <template>
    <DButton
      class="isbf-topic-card__reply reply"
      data-isbf-action-count={{this.count}}
      data-isbf-post-action="reply"
      ...attributes
      @action={{this.reply}}
      @disabled={{if @state.currentUser (if @state.canCreatePost false true)}}
      @icon="comment"
      @translatedAriaLabel={{i18n
        "post.sr_reply_to"
        post_number=@post.post_number
        username=@post.username
      }}
      {{postActionPulse this.pulse}}
    ><ISBFPostActionCount
        @kind="reply"
        @pulse={{this.pulse}}
        @value={{this.count}}
      /></DButton>
  </template>
}

export class ISBFTopicRepost extends Component {
  @service composer;
  @service currentUser;
  @service router;

  @tracked busy = false;

  pulse = new PostActionPulse();

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
      this.pulse.settle("repost");
      if (!this.isDestroying) {
        this.busy = false;
      }
    }
  }

  <template>
    <DButton
      class="isbf-topic-card__repost"
      data-isbf-post-action="repost"
      ...attributes
      @action={{this.repost}}
      @disabled={{this.busy}}
      @icon="retweet"
      @translatedAriaLabel={{i18n (themePrefix "isbf_v2.repost")}}
      {{postActionPulse this.pulse}}
    />
  </template>
}

export class ISBFTopicLike extends Component {
  pulse = new PostActionPulse();

  get buttonActions() {
    return { ...this.args.buttonActions, toggleLike: this.toggleLike };
  }

  get showNativeButton() {
    return this.args.post.showLike || this.args.post.likeCount;
  }

  @action
  async toggleLike() {
    try {
      return await this.args.buttonActions.toggleLike();
    } finally {
      this.pulse.settle("like");
    }
  }

  <template>
    <div
      class="isbf-topic-card__like"
      data-isbf-action-count={{@post.likeCount}}
      data-isbf-post-action="like"
      ...attributes
      {{postActionPulse this.pulse}}
    >
      {{#if this.showNativeButton}}
        <PostMenuLikeButton
          @animate={{false}}
          @buttonActions={{this.buttonActions}}
          @post={{@post}}
          @showLabel={{false}}
          @state={{@state}}
        >
          <:count as |count|>
            <ISBFPostActionCount
              @format="integer"
              @kind="like"
              @pulse={{this.pulse}}
              @value={{count}}
            />
          </:count>
        </PostMenuLikeButton>
      {{else}}
        <DButton
          class="btn-flat"
          @disabled={{true}}
          @icon="heart"
          @title="post.controls.like"
        />
      {{/if}}
    </div>
  </template>
}

export class ISBFTopicBookmark extends Component {
  @service currentUser;
  @service router;

  @tracked busy = false;

  pulse = new PostActionPulse();

  get isFirstPost() {
    return this.args.post.post_number === 1;
  }

  get bookmarked() {
    return this.isFirstPost
      ? get(this.args.post.topic, "bookmarked")
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
        await ajax(`/t/${topic.id}/remove_bookmarks`, { type: "PUT" });
        topic.set("bookmarked", false);
      } else {
        await ajax(`/t/${topic.id}/bookmark`, { type: "PUT" });
        topic.set("bookmarked", true);
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.pulse.settle("bookmark");
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
      data-isbf-post-action="bookmark"
      ...attributes
      {{postActionPulse this.pulse}}
    >
      {{#if this.isFirstPost}}
        <DButton
          class="btn-flat"
          @action={{this.bookmark}}
          @ariaPressed={{this.bookmarked}}
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
