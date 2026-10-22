import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import PostAvatar from "discourse/components/post/avatar";
import PostCookedHtml from "discourse/components/post/cooked-html";
import PostMetaData from "discourse/components/post/meta-data";
import DMenu from "discourse/float-kit/components/d-menu";
import { not, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";

export default class NestedDeletedPosts extends Component {
  @service currentUser;

  @tracked expanded = false;
  @tracked revealed = new Set();
  @tracked recovering = null;

  #lastTarget;

  constructor() {
    super(...arguments);
    this.revealTarget();
  }

  get firstPost() {
    return this.args.posts[0];
  }

  get multiple() {
    return this.args.posts.length > 1;
  }

  get label() {
    return i18n("nested_replies.deleted_replies", {
      count: this.args.posts.length,
    });
  }

  get entries() {
    return this.args.posts.map((post) => ({
      post,
      revealed: this.revealed.has(post.id),
      canView: Boolean(
        this.currentUser?.staff && post.cooked && !post.cooked_hidden
      ),
      canRecover: Boolean(post.can_recover),
      recovering: this.recovering === post.id,
    }));
  }

  @action
  revealTarget() {
    const target = this.args.targetPostNumber;
    if (target === this.#lastTarget) {
      return;
    }
    this.#lastTarget = target;
    if (this.args.posts.some((post) => post.post_number === Number(target))) {
      this.expanded = true;
    }
  }

  @action
  toggle() {
    this.expanded = !this.expanded;
  }

  @action
  async toggleContent(menu, post) {
    await menu.close();
    const revealed = new Set(this.revealed);
    if (revealed.has(post.id)) {
      revealed.delete(post.id);
    } else {
      revealed.add(post.id);
    }
    this.revealed = revealed;
  }

  @action
  async recover(menu, post) {
    await menu.close();
    if (this.recovering) {
      return;
    }
    this.recovering = post.id;
    try {
      await this.args.recoverPost(post);
    } finally {
      this.recovering = null;
    }
  }

  <template>
    <div
      class="nested-post__placeholder nested-deleted-posts"
      {{didUpdate this.revealTarget @targetPostNumber @posts}}
    >
      {{#if this.multiple}}
        <DButton
          class="btn-flat nested-deleted-posts__summary"
          data-post-number={{unless this.expanded this.firstPost.post_number}}
          @action={{this.toggle}}
          @ariaExpanded={{this.expanded}}
          @icon={{if this.expanded "chevron-down" "chevron-right"}}
          @translatedLabel={{this.label}}
        />
      {{/if}}
      {{#if (or this.expanded (not this.multiple))}}
        {{#each this.entries key="post.id" as |entry|}}
          <div
            class="nested-post__placeholder nested-deleted-posts__entry"
            data-post-number={{entry.post.post_number}}
          >
            <div class="nested-deleted-posts__row">
              <span>{{i18n "nested_replies.deleted_reply"}}</span>
              {{#if (or entry.canView entry.canRecover)}}
                <DMenu
                  @ariaLabel={{i18n "more"}}
                  @icon="ellipsis"
                  @modalForMobile={{true}}
                  @title={{i18n "more"}}
                  @triggerClass="btn-flat nested-deleted-posts__more"
                >
                  <:content as |menu|>
                    <DDropdownMenu as |dropdown|>
                      {{#if entry.canView}}
                        <dropdown.item>
                          <DButton
                            @action={{fn this.toggleContent menu entry.post}}
                            @icon={{if
                              entry.revealed
                              "far-eye-slash"
                              "far-eye"
                            }}
                            @label="post.controls.view_deleted"
                          />
                        </dropdown.item>
                      {{/if}}
                      {{#if entry.canRecover}}
                        <dropdown.item>
                          <DButton
                            @action={{fn this.recover menu entry.post}}
                            @disabled={{entry.recovering}}
                            @icon="arrow-rotate-left"
                            @label="post.controls.undelete"
                          />
                        </dropdown.item>
                      {{/if}}
                    </DDropdownMenu>
                  </:content>
                </DMenu>
              {{/if}}
            </div>
            {{#if entry.revealed}}
              <div class="nested-post__placeholder-reveal">
                <div class="nested-post__placeholder-reveal-header">
                  <PostAvatar @post={{entry.post}} @size="small" />
                  <PostMetaData @post={{entry.post}} />
                </div>
                <PostCookedHtml @post={{entry.post}} />
              </div>
            {{/if}}
          </div>
        {{/each}}
      {{/if}}
    </div>
  </template>
}
