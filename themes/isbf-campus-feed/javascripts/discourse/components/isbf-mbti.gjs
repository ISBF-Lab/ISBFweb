import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import {
  clearForeignMbtiDrafts,
  mbtiConfig,
  mbtiError,
  newMbtiAttemptId,
  readMbtiDrafts,
  saveMbtiDrafts,
} from "../lib/mbti";
import ISBFMbtiHistory from "./isbf-mbti-history";
import ISBFMbtiIntro from "./isbf-mbti-intro";
import ISBFMbtiQuestion from "./isbf-mbti-question";
import ISBFMbtiResult from "./isbf-mbti-result";

const API = "/isbf/api/mbti";

export default class ISBFMbti extends Component {
  @service appEvents;
  @service currentUser;
  @service dialog;
  @service isbfBackNavigation;
  @service keyValueStore;
  @service site;

  @tracked answers = {};
  @tracked busy = false;
  @tracked cleanupFailed = false;
  @tracked drafts = {};
  @tracked error = null;
  @tracked hasMore = false;
  @tracked history = [];
  @tracked index = 0;
  @tracked page = 0;
  @tracked questionnaire = null;
  @tracked questionnaires = [];
  @tracked result = null;
  @tracked selectedVariant = "40";
  @tracked staleDraft = false;
  @tracked storageUnavailable = false;
  @tracked view = "intro";

  #attemptId;
  #historyRetryPage = null;
  #requestId = 0;

  constructor() {
    super(...arguments);
    scheduleOnce("afterRender", this, this.load);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#requestId++;
  }

  get available() {
    return Boolean(mbtiConfig(this.site));
  }

  get backHref() {
    return "/isbf/workbench";
  }

  get draft() {
    return this.drafts[this.selectedVariant];
  }

  get historyRows() {
    return this.history.map((entry) => ({
      ...entry,
      createdLabel: new Date(entry.created_at).toLocaleString(),
    }));
  }

  get isHistory() {
    return this.view === "history";
  }

  get isIntro() {
    return this.view === "intro";
  }

  get isQuiz() {
    return this.view === "quiz";
  }

  get isResult() {
    return this.view === "result";
  }

  get last() {
    return this.index === this.questionnaire?.questions.length - 1;
  }

  get position() {
    return this.index + 1;
  }

  get question() {
    return this.questionnaire?.questions[this.index];
  }

  get questionRows() {
    return this.question ? [this.question] : [];
  }

  get selectedChoice() {
    return this.answers[this.question?.id];
  }

  get storageMessage() {
    return this.#message(
      this.cleanupFailed ? "mbti_cleanup_failed" : "mbti_storage_unavailable"
    );
  }

  get versions() {
    return this.questionnaires.map((meta) => ({
      ...meta,
      selected: meta.variant === this.selectedVariant,
      label: i18n(themePrefix("isbf_v2.mbti_version"), {
        count: meta.question_count,
      }),
      recommended: meta.variant === "40",
    }));
  }

  @action
  accountChanged() {
    this.#requestId++;
    clearForeignMbtiDrafts(this.keyValueStore, this.currentUser?.id);
    this.answers = {};
    this.drafts = {};
    this.history = [];
    this.questionnaire = null;
    this.result = null;
    this.view = "intro";
    this.staleDraft = false;
    this.storageUnavailable = false;
    this.cleanupFailed = false;
    this.hasMore = false;
    this.page = 0;
    this.#historyRetryPage = null;
    this.busy = false;
    this.load();
  }

  @action
  goBack(event) {
    if (this.busy) {
      event.preventDefault();
      return;
    }
    if (!this.isIntro) {
      event.preventDefault();
      this.view = "intro";
      this.error = null;
      return;
    }
    this.isbfBackNavigation.back(event);
  }

  @action
  login() {
    this.appEvents.trigger("show-login");
  }

  @action
  async load() {
    if (!this.available || this.busy) {
      return;
    }
    const token = ++this.#requestId;
    const owner = this.currentUser?.id;
    this.busy = true;
    this.error = null;
    try {
      const response = await ajax(`${API}/questionnaires.json`);
      if (!this.#active(token, owner)) {
        return;
      }
      this.questionnaires = response.questionnaires;
      const restored = readMbtiDrafts(
        this.keyValueStore,
        owner,
        this.questionnaires
      );
      this.drafts = restored.drafts;
      this.staleDraft = restored.stale;
      if (restored.stale) {
        saveMbtiDrafts(this.keyValueStore, owner, this.drafts);
      }
    } catch (error) {
      if (this.#active(token, owner)) {
        this.error = mbtiError(error, this.#message("mbti_load_failed"));
      }
    } finally {
      if (this.#active(token, owner)) {
        this.busy = false;
      }
    }
  }

  @action
  selectVariant(variant) {
    if (!this.busy) {
      this.selectedVariant = variant;
      this.error = null;
    }
  }

  @action
  async start() {
    if (this.busy || !this.currentUser) {
      return;
    }
    const token = ++this.#requestId;
    const owner = this.currentUser.id;
    if (this.draft) {
      this.busy = true;
      try {
        const confirmed = await this.dialog.confirm({
          message: this.#message("mbti_restart_confirm"),
        });
        if (!confirmed || !this.#active(token, owner)) {
          return;
        }
      } finally {
        if (this.#active(token, owner)) {
          this.busy = false;
        }
      }
    }
    if (this.#active(token, owner)) {
      return this.#openQuestionnaire(false);
    }
  }

  @action
  resume() {
    if (this.draft && !this.busy) {
      return this.#openQuestionnaire(true);
    }
  }

  @action
  selectChoice(choice) {
    if (!this.busy && this.currentUser && this.question) {
      this.answers = { ...this.answers, [this.question.id]: choice };
      this.#persistDraft();
    }
  }

  @action
  previous() {
    if (!this.busy && this.index > 0) {
      this.index--;
      this.#persistDraft();
    }
  }

  @action
  next() {
    if (this.busy || !this.selectedChoice) {
      return;
    }
    if (this.last) {
      return this.submit();
    }
    this.index++;
    this.#persistDraft();
  }

  @action
  async submit() {
    if (
      this.busy ||
      !this.currentUser ||
      this.questionnaire.questions.some(
        (question) => !this.answers[question.id]
      )
    ) {
      return;
    }
    const token = ++this.#requestId;
    const owner = this.currentUser.id;
    this.busy = true;
    this.error = null;
    try {
      const response = await ajax(`${API}/results.json`, {
        type: "POST",
        contentType: "application/json",
        data: JSON.stringify({
          variant: this.questionnaire.variant,
          version: this.questionnaire.version,
          attempt_id: this.#attemptId,
          answers: this.questionnaire.questions.map((question) => ({
            id: question.id,
            choice: this.answers[question.id],
          })),
        }),
      });
      if (this.#active(token, owner)) {
        this.result = response.result;
        this.#removeDraft(this.questionnaire.variant);
        this.answers = {};
        this.#attemptId = null;
        this.questionnaire = null;
        this.view = "result";
      }
    } catch (error) {
      if (this.#active(token, owner)) {
        this.error = mbtiError(error, this.#message("mbti_save_failed"));
      }
    } finally {
      if (this.#active(token, owner)) {
        this.busy = false;
      }
    }
  }

  @action
  async discard() {
    if (this.busy) {
      return;
    }
    const owner = this.currentUser?.id;
    if (
      await this.dialog.confirm({
        message: this.#message("mbti_discard_confirm"),
      })
    ) {
      if (this.isDestroying || owner !== this.currentUser?.id) {
        return;
      }
      this.#removeDraft(this.questionnaire.variant);
      this.answers = {};
      this.questionnaire = null;
      this.#attemptId = null;
      this.view = "intro";
      this.error = null;
    }
  }

  @action
  showHistory() {
    if (this.currentUser && !this.busy) {
      this.view = "history";
      this.result = null;
      return this.#loadHistory(0);
    }
  }

  @action
  loadMore() {
    if (!this.busy && this.hasMore) {
      return this.#loadHistory(this.page + 1);
    }
  }

  @action
  async openResult(id) {
    if (this.busy || !this.currentUser) {
      return;
    }
    const token = ++this.#requestId;
    const owner = this.currentUser.id;
    this.busy = true;
    this.error = null;
    try {
      const response = await ajax(`${API}/results/${id}.json`);
      if (this.#active(token, owner)) {
        this.result = response.result;
        this.view = "result";
      }
    } catch (error) {
      if (this.#active(token, owner)) {
        this.error = mbtiError(error, this.#message("mbti_load_failed"));
      }
    } finally {
      if (this.#active(token, owner)) {
        this.busy = false;
      }
    }
  }

  @action
  retest() {
    if (!this.busy) {
      this.view = "intro";
      this.result = null;
      this.error = null;
    }
  }

  @action
  async deleteResult() {
    if (!this.result || this.busy || !this.currentUser) {
      return;
    }
    const token = ++this.#requestId;
    const owner = this.currentUser.id;
    const id = this.result.id;
    this.busy = true;
    this.error = null;
    try {
      const confirmed = await this.dialog.confirm({
        message: this.#message("mbti_delete_confirm"),
        confirmButtonLabel: themePrefix("isbf_v2.mbti_delete_result"),
      });
      if (!confirmed || !this.#active(token, owner)) {
        return;
      }
      await ajax(`${API}/results/${id}.json`, { type: "DELETE" });
      if (this.#active(token, owner)) {
        this.result = null;
        this.view = "history";
        await this.#loadHistory(0);
      }
    } catch (error) {
      if (this.#active(token, owner)) {
        this.error = mbtiError(error, this.#message("mbti_delete_failed"));
      }
    } finally {
      if (this.#active(token, owner)) {
        this.busy = false;
      }
    }
  }

  @action
  retry() {
    return this.isHistory
      ? this.#loadHistory(this.#historyRetryPage ?? 0)
      : this.load();
  }

  #active(token, owner) {
    return (
      !this.isDestroying &&
      token === this.#requestId &&
      owner === this.currentUser?.id
    );
  }

  #message(key) {
    return i18n(themePrefix(`isbf_v2.${key}`));
  }

  async #openQuestionnaire(resume) {
    const token = ++this.#requestId;
    const owner = this.currentUser?.id;
    const draft = resume ? this.draft : null;
    const selected = this.selectedVariant;
    this.busy = true;
    this.error = null;
    try {
      const { questionnaire } = await ajax(
        `${API}/questionnaires/${selected}.json`
      );
      if (!this.#active(token, owner)) {
        return;
      }
      if (draft && draft.version !== questionnaire.version) {
        this.#removeDraft(selected);
        this.staleDraft = true;
        return;
      }
      this.questionnaire = questionnaire;
      this.answers = draft ? { ...draft.answers } : {};
      this.index = draft?.index || 0;
      this.#attemptId = draft?.attempt_id || newMbtiAttemptId();
      this.view = "quiz";
      this.staleDraft = false;
      this.#persistDraft();
    } catch (error) {
      if (this.#active(token, owner)) {
        this.error = mbtiError(error, this.#message("mbti_load_failed"));
      }
    } finally {
      if (this.#active(token, owner)) {
        this.busy = false;
      }
    }
  }

  #persistDraft() {
    this.cleanupFailed = false;
    const variant = this.questionnaire.variant;
    this.drafts = {
      ...this.drafts,
      [variant]: {
        variant,
        version: this.questionnaire.version,
        attempt_id: this.#attemptId,
        index: this.index,
        answers: this.answers,
      },
    };
    this.storageUnavailable = !saveMbtiDrafts(
      this.keyValueStore,
      this.currentUser.id,
      this.drafts
    );
  }

  #removeDraft(variant) {
    const drafts = { ...this.drafts };
    delete drafts[variant];
    this.drafts = drafts;
    this.cleanupFailed = !saveMbtiDrafts(
      this.keyValueStore,
      this.currentUser.id,
      drafts
    );
    this.storageUnavailable = this.cleanupFailed;
  }

  async #loadHistory(page) {
    this.#historyRetryPage = page;
    const token = ++this.#requestId;
    const owner = this.currentUser.id;
    this.busy = true;
    this.error = null;
    try {
      const response = await ajax(`${API}/results.json`, { data: { page } });
      if (this.#active(token, owner)) {
        this.history = page
          ? [...this.history, ...response.results]
          : response.results;
        this.hasMore = response.has_more;
        this.page = page;
        this.#historyRetryPage = null;
      }
    } catch (error) {
      if (this.#active(token, owner)) {
        this.error = mbtiError(error, this.#message("mbti_load_failed"));
      }
    } finally {
      if (this.#active(token, owner)) {
        this.busy = false;
      }
    }
  }

  <template>
    <main
      aria-busy={{this.busy}}
      class="isbf-mbti"
      {{didUpdate this.accountChanged this.currentUser.id}}
    >
      <header class="isbf-mbti__header">
        <a
          aria-label={{i18n "back_button"}}
          href={{this.backHref}}
          {{on "click" this.goBack}}
        >{{dIcon "arrow-left"}}</a>
        <h1>{{i18n (themePrefix "isbf_v2.workbench_mbti")}}</h1>
        {{#if this.currentUser}}
          {{#unless this.isQuiz}}
            <DButton
              data-test-mbti-history
              @action={{this.showHistory}}
              @disabled={{this.busy}}
              @label={{themePrefix "isbf_v2.mbti_history"}}
            />
          {{/unless}}
        {{/if}}
      </header>
      <div class="isbf-mbti__body">
        {{#if this.available}}
          {{#if this.error}}
            <div class="isbf-mbti__error" role="alert">
              <p>{{this.error}}</p>
              {{#unless this.isQuiz}}<DButton
                  data-test-mbti-retry
                  @action={{this.retry}}
                  @disabled={{this.busy}}
                  @label={{themePrefix "isbf_v2.mbti_retry"}}
                />{{/unless}}
            </div>
          {{/if}}
          {{#if this.storageUnavailable}}<p
              class="isbf-mbti__muted"
              data-test-mbti-storage-warning
              role="status"
            >{{this.storageMessage}}</p>{{/if}}
          {{#if this.isIntro}}
            <ISBFMbtiIntro
              @busy={{this.busy}}
              @hasDraft={{if this.draft true false}}
              @loggedIn={{if this.currentUser true false}}
              @onLogin={{this.login}}
              @onResume={{this.resume}}
              @onSelectVariant={{this.selectVariant}}
              @onStart={{this.start}}
              @ready={{this.questionnaires.length}}
              @staleDraft={{this.staleDraft}}
              @versions={{this.versions}}
            />
          {{else if this.isQuiz}}
            {{#each this.questionRows key="id" as |question|}}
              <ISBFMbtiQuestion
                @choice={{this.selectedChoice}}
                @first={{unless this.index true}}
                @last={{this.last}}
                @onChoice={{this.selectChoice}}
                @onNext={{this.next}}
                @onPrevious={{this.previous}}
                @position={{this.position}}
                @question={{question}}
                @saving={{this.busy}}
                @total={{this.questionnaire.question_count}}
              />
            {{/each}}
            <DButton
              class="isbf-mbti__discard"
              @action={{this.discard}}
              @disabled={{this.busy}}
              @label={{themePrefix "isbf_v2.mbti_discard"}}
            />
          {{else if this.isResult}}
            <ISBFMbtiResult
              @busy={{this.busy}}
              @onDelete={{this.deleteResult}}
              @onRetest={{this.retest}}
              @result={{this.result}}
            />
          {{else if this.isHistory}}
            <ISBFMbtiHistory
              @busy={{this.busy}}
              @entries={{this.historyRows}}
              @error={{this.error}}
              @hasMore={{this.hasMore}}
              @onLoadMore={{this.loadMore}}
              @onOpen={{this.openResult}}
            />
          {{/if}}
          {{#if this.busy}}<p class="isbf-mbti__muted" role="status">{{i18n
                "loading"
              }}</p>{{/if}}
        {{else}}
          <p role="status">{{i18n (themePrefix "isbf_v2.mbti_unavailable")}}</p>
        {{/if}}
      </div>
    </main>
  </template>
}
