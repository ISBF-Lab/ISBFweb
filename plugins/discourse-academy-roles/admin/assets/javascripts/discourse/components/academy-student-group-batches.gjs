import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { registerDestructor } from "@ember/destroyable";
import { concat, fn } from "@ember/helper";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { longDate } from "discourse/lib/formatter";
import { eq, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";
import AcademyStudentGroupForm from "./academy-student-group-form";
import AcademyStudentGroupItems from "./academy-student-group-items";

const BASE = "/academy-roles/admin/student-group-batches";

export default class AcademyStudentGroupBatches extends Component {
  @service currentUser;
  @service dialog;
  @service messageBus;
  @service router;

  @tracked busy = false;
  @tracked response;
  @tracked selectedIds = [];
  @tracked history = [];
  @tracked historyHasMore = false;
  @tracked historyPage = 0;
  @tracked refreshError = false;

  #channel;
  #refreshing = false;
  #refreshPending = false;
  #requestSequence = 0;
  #onProgress = (message) => {
    if (message.id === this.batch?.id && message.version > this.batch.version) {
      this.refresh();
    }
  };

  constructor() {
    super(...arguments);
    this.response = this.args.model.result;
    this.selectedIds = this.response?.batch.selected_item_ids || [];
    this.history = this.args.model.history?.batches || [];
    this.historyHasMore = this.args.model.history?.has_more;
    this.#subscribe();
    registerDestructor(this, () => this.#unsubscribe());
  }

  get batch() {
    return this.response?.batch;
  }

  get downloadUrl() {
    return `${BASE}/${this.batch.id}/download.csv`;
  }

  get counts() {
    return Object.entries(this.batch?.counts || {}).map(([status, count]) => ({
      status: i18n(`academy_roles.student_groups.states.${status}`),
      count,
    }));
  }

  get executeDisabled() {
    return (
      this.busy ||
      !this.selectedIds.length ||
      (this.batch?.expires_at && new Date(this.batch.expires_at) <= new Date())
    );
  }

  get running() {
    return ["queued", "running"].includes(this.batch?.state);
  }

  get previousDisabled() {
    return this.busy || !this.response.page;
  }

  @action
  invalidate() {
    if (this.batch?.state === "preview") {
      this.#unsubscribe();
      this.#requestSequence++;
      this.response = null;
      this.selectedIds = [];
    }
  }

  @action
  async preview(data) {
    if (this.busy) {
      return;
    }
    this.busy = true;
    try {
      const response = await ajax(`${BASE}/preview.json`, {
        type: "POST",
        processData: false,
        contentType: false,
        data,
      });
      await this.router.transitionTo(
        "adminPlugins.show.academy-student-group-batches.batch",
        response.batch.id
      );
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busy = false;
      this.#flushRefresh();
    }
  }

  @action
  select(id, event) {
    const ids = new Set(this.selectedIds);
    if (event.target.checked) {
      ids.add(id);
    } else {
      ids.delete(id);
    }
    this.selectedIds = [...ids];
  }

  @action
  selectAll() {
    this.selectedIds = [...(this.batch.selectable_item_ids || [])];
  }

  @action
  selectNone() {
    this.selectedIds = [];
  }

  @action
  execute() {
    if (this.executeDisabled) {
      return;
    }
    this.#confirm("execute", { selected_item_ids: [...this.selectedIds] });
  }

  @action
  retry() {
    if (!this.busy) {
      this.#confirm("retry");
    }
  }

  @action
  undo() {
    if (!this.busy) {
      return this.#post("undo-preview");
    }
  }

  @action
  async page(delta) {
    if (this.busy) {
      return;
    }
    this.busy = true;
    try {
      await this.#fetchPage((this.response.page || 0) + delta);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busy = false;
      this.#flushRefresh();
    }
  }

  @action
  async refresh() {
    if (!this.batch) {
      return;
    }
    if (this.#refreshing || this.busy) {
      this.#refreshPending = true;
      return;
    }
    this.#refreshing = true;
    this.refreshError = false;
    try {
      await this.#fetchPage(this.response.page || 0);
    } catch {
      this.refreshError = true;
    } finally {
      this.#refreshing = false;
      this.#flushRefresh();
    }
  }

  @action
  async loadHistory() {
    if (this.busy) {
      return;
    }
    this.busy = true;
    try {
      const response = await ajax(`${BASE}.json`, {
        data: { page: this.historyPage + 1 },
      });
      this.history = [...this.history, ...response.batches];
      this.historyHasMore = response.has_more;
      this.historyPage++;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busy = false;
      this.#flushRefresh();
    }
  }

  #confirm(operation, data) {
    this.busy = true;
    this.dialog.confirm({
      message: i18n(`academy_roles.student_groups.confirm_${operation}`, {
        count: this.selectedIds.length,
      }),
      didCancel: () => {
        this.busy = false;
        this.#flushRefresh();
      },
      didConfirm: () => {
        this.busy = false;
        return this.#post(operation, data);
      },
    });
  }

  async #post(operation, data) {
    if (this.busy || this.isDestroying || !this.batch) {
      return;
    }
    this.busy = true;
    try {
      const response = await ajax(
        `${BASE}/${this.batch.id}/${operation}.json`,
        {
          type: "POST",
          data: JSON.stringify(data || {}),
          contentType: "application/json",
        }
      );
      if (operation === "undo-preview") {
        await this.router.transitionTo(
          "adminPlugins.show.academy-student-group-batches.batch",
          response.batch.id
        );
      } else {
        this.#requestSequence++;
        this.response = response;
        this.selectedIds = response.batch.selected_item_ids || [];
        this.#subscribe();
      }
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.busy = false;
      this.#flushRefresh();
    }
  }

  async #fetchPage(page) {
    const batchId = this.batch?.id;
    if (!batchId) {
      return;
    }
    const requestSequence = ++this.#requestSequence;
    const response = await ajax(`${BASE}/${batchId}.json`, { data: { page } });
    if (
      !this.isDestroying &&
      this.batch?.id === batchId &&
      requestSequence === this.#requestSequence
    ) {
      const wasPreview = this.batch.state === "preview";
      this.response = response;
      if (!wasPreview || response.batch.state !== "preview") {
        this.selectedIds = response.batch.selected_item_ids || [];
      }
      this.#subscribe();
    }
  }

  #flushRefresh() {
    if (
      this.#refreshPending &&
      !this.busy &&
      !this.#refreshing &&
      this.batch &&
      !this.isDestroying
    ) {
      this.#refreshPending = false;
      this.refresh();
    }
  }

  #subscribe() {
    const channel = this.batch?.message_bus_channel;
    if (channel === this.#channel) {
      return;
    }
    this.#unsubscribe();
    if (channel) {
      this.#channel = channel;
      this.messageBus.subscribe(channel, this.#onProgress);
    }
  }

  #unsubscribe() {
    if (this.#channel) {
      this.messageBus.unsubscribe(this.#channel, this.#onProgress);
      this.#channel = null;
    }
  }

  <template>
    {{#if this.currentUser.admin}}
      <div
        class="admin-config-page__main-area academy-student-group-batches"
        ...attributes
      >
        <DPageSubheader
          @descriptionLabel={{i18n "academy_roles.student_groups.description"}}
          @titleLabel={{i18n "academy_roles.student_groups.title"}}
        />
        <AcademyStudentGroupForm
          @busy={{or this.busy this.running}}
          @onInvalidate={{this.invalidate}}
          @onPreview={{this.preview}}
          @options={{@model.options}}
        />
        {{#if this.batch}}
          <section
            aria-label={{i18n "academy_roles.student_groups.result"}}
            class="academy-student-group-batches__result"
          >
            <p role="status">{{i18n
                "academy_roles.student_groups.batch_number"
                id=this.batch.id
              }}:
              {{i18n
                (concat "academy_roles.student_groups.states." this.batch.state)
              }}</p>
            {{#if this.batch.duplicate_count}}
              <p>{{i18n
                  "academy_roles.student_groups.duplicates_skipped"
                  count=this.batch.duplicate_count
                }}</p>
            {{/if}}
            {{#if this.batch.source_batch_id}}<p>{{i18n
                  "academy_roles.student_groups.undo_of"
                  id=this.batch.source_batch_id
                }}</p>{{/if}}
            {{#if this.batch.expires_at}}<p>{{i18n
                  "academy_roles.student_groups.expires"
                }}
                {{longDate this.batch.expires_at}}</p>{{/if}}
            <p>{{i18n "academy_roles.student_groups.add"}}:
              {{#each this.batch.add_groups as |group|}}<span>{{group.name}}
                </span>{{/each}}</p>
            <p>{{i18n "academy_roles.student_groups.remove"}}:
              {{#each this.batch.remove_groups as |group|}}<span>{{group.name}}
                </span>{{/each}}</p>
            <ul aria-live="polite">{{#each this.counts as |entry|}}<li
                >{{entry.status}}: {{entry.count}}</li>{{/each}}</ul>
            {{#if this.refreshError}}<p
                class="alert alert-error"
                role="alert"
              >{{i18n "academy_roles.student_groups.refresh_error"}}</p><DButton
                @action={{this.refresh}}
                @disabled={{this.busy}}
                @label="academy_roles.student_groups.refresh"
              />{{/if}}
            {{#if (eq this.batch.state "preview")}}
              <p role="status">{{i18n
                  "academy_roles.student_groups.selected"
                  count=this.selectedIds.length
                }}</p>
              <DButton
                @action={{this.selectAll}}
                @disabled={{this.busy}}
                @label="academy_roles.student_groups.select_all"
              />
              <DButton
                @action={{this.selectNone}}
                @disabled={{this.busy}}
                @label="academy_roles.student_groups.select_none"
              />
              <DButton
                class="btn-primary"
                @action={{this.execute}}
                @disabled={{this.executeDisabled}}
                @label="academy_roles.student_groups.execute"
              />
            {{/if}}
            <AcademyStudentGroupItems
              @busy={{this.busy}}
              @items={{this.response.items}}
              @onSelect={{this.select}}
              @preview={{eq this.batch.state "preview"}}
              @selectedIds={{this.selectedIds}}
            />
            <DButton
              @action={{fn this.page -1}}
              @disabled={{this.previousDisabled}}
              @label="academy_roles.student_groups.previous"
            />
            <DButton
              @action={{fn this.page 1}}
              @disabled={{or this.busy (eq this.response.has_more false)}}
              @label="academy_roles.student_groups.next"
            />
            {{#if this.batch.can_retry}}<DButton
                @action={{this.retry}}
                @disabled={{this.busy}}
                @label="academy_roles.student_groups.retry"
              />{{/if}}
            {{#if this.batch.can_undo}}<DButton
                @action={{this.undo}}
                @disabled={{this.busy}}
                @label="academy_roles.student_groups.undo_preview"
              />{{/if}}
            <a href={{this.downloadUrl}}>{{i18n
                "academy_roles.student_groups.download"
              }}</a>
          </section>
        {{/if}}
        <h2>{{i18n "academy_roles.student_groups.history"}}</h2>
        <ul>{{#each this.history as |batch|}}<li><LinkTo
                @model={{batch.id}}
                @route="adminPlugins.show.academy-student-group-batches.batch"
              >{{i18n "academy_roles.student_groups.batch_number" id=batch.id}}:
                {{i18n
                  (concat "academy_roles.student_groups.states." batch.state)
                }}</LinkTo></li>{{else}}<li>{{i18n
                "academy_roles.student_groups.empty"
              }}</li>{{/each}}</ul>
        {{#if this.historyHasMore}}<DButton
            @action={{this.loadHistory}}
            @disabled={{this.busy}}
            @label="academy_roles.student_invites.load_more"
          />{{/if}}
      </div>
    {{/if}}
  </template>
}
