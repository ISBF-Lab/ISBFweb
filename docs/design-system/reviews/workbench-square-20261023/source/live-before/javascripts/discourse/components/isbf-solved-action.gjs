import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { isFeedStylePost } from "../lib/topic-card-scope";

const wrappers = new WeakMap();

export default function solvedActionFor(NativeAction) {
  if (typeof NativeAction !== "function") {
    return null;
  }
  if (wrappers.has(NativeAction)) {
    return wrappers.get(NativeAction);
  }

  class ISBFSolvedAction extends NativeAction {
    static hidden() {
      return false;
    }

    @service router;
    @service siteSettings;

    get accepted() {
      return Boolean(this.args.post.accepted_answer);
    }

    get enabled() {
      return Boolean(
        this.siteSettings.solved_enabled &&
        this.args.post.post_number > 1 &&
        isFeedStylePost(
          this.args.post,
          this.router.currentURL,
          this.args.state?.nestedReplyView
        ) &&
        (this.accepted || this.args.post.can_accept_answer)
      );
    }

    get nativeAction() {
      return this.accepted ? this.unacceptAnswer : this.acceptAnswer;
    }

    get canAct() {
      return (
        this.enabled &&
        this.args.post.can_accept_answer &&
        typeof this.nativeAction === "function"
      );
    }

    get label() {
      return i18n(
        themePrefix(
          this.accepted ? "isbf_v2.solved_unaccept" : "isbf_v2.solved_accept"
        )
      );
    }

    get title() {
      const username =
        this.accepted &&
        this.siteSettings.show_who_marked_solved &&
        this.answerInfo?.accepter_username;
      return username
        ? i18n(themePrefix("isbf_v2.solved_accepted_by"), { username })
        : this.label;
    }

    @action
    async runNativeAction() {
      if (
        !this.canAct ||
        this.saving ||
        this.isDestroying ||
        this.isDestroyed
      ) {
        return;
      }
      await this.nativeAction();
    }

    <template>
      {{#if this.enabled}}
        <div class="isbf-solved-action" ...attributes>
          {{#if this.accepted}}
            <span class="isbf-solved-action__status">
              {{dIcon "check"}}
              {{i18n (themePrefix "isbf_v2.solved_accepted")}}
            </span>
          {{/if}}
          {{#if this.canAct}}
            <DButton
              class="isbf-solved-action__button"
              @action={{this.runNativeAction}}
              @disabled={{this.saving}}
              @icon={{if this.accepted "square-check" "far-square-check"}}
              @translatedLabel={{this.label}}
              @translatedTitle={{this.title}}
            />
          {{/if}}
        </div>
      {{/if}}
    </template>
  }

  wrappers.set(NativeAction, ISBFSolvedAction);
  return ISBFSolvedAction;
}
