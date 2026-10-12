import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import { officialTimeLabel } from "../lib/official-calendar";

export default class ISBFCalendarUpdateDialog extends Component {
  @tracked error = false;
  @tracked isSaving = false;
  @tracked versionChanged = false;
  @tracked _refreshedEntry = null;

  get entry() {
    return this._refreshedEntry ?? this.args.model.entry;
  }

  get currentTime() {
    return officialTimeLabel(this.entry);
  }

  get latestTime() {
    return officialTimeLabel(this.entry.latest_source);
  }

  get canAccept() {
    return (
      this.entry.needs_update &&
      !this.entry.cancelled &&
      !this.entry.source_unavailable
    );
  }

  @action
  accept() {
    return this.#respond(true);
  }

  @action
  dismiss() {
    return this.#respond(false);
  }

  @action
  async remove() {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      if (await this.args.model.onRemove(this.entry)) {
        this.args.closeModal();
      }
    } finally {
      if (!this.isDestroying) {
        this.isSaving = false;
      }
    }
  }

  async #respond(accept) {
    if (this.isSaving || !this.entry.latest_source) {
      return;
    }
    this.isSaving = true;
    this.error = false;
    this.versionChanged = false;
    try {
      const response = await ajax(
        `/isbf/api/entries/${this.entry.id}/${accept ? "accept-update" : "dismiss-update"}.json`,
        {
          type: "POST",
          data: { revision: this.entry.latest_source.revision },
        }
      );
      this.args.model.onChanged(response?.entry || this.entry, accept);
      this.args.closeModal();
    } catch (error) {
      if (error.jqXHR?.status === 409) {
        try {
          const { entry } = await ajax(
            `/isbf/api/entries/${this.entry.id}.json`
          );
          if (!this.isDestroying) {
            this._refreshedEntry = entry;
            this.versionChanged = true;
            this.args.model.onChanged(entry);
          }
        } catch {
          this.error = true;
        }
      } else {
        this.error = true;
      }
    } finally {
      if (!this.isDestroying) {
        this.isSaving = false;
      }
    }
  }

  <template>
    <DModal
      class="isbf-calendar-update-dialog"
      @closeModal={{@closeModal}}
      @title={{i18n (themePrefix "isbf_v2.schedule_review")}}
    >
      <:body>
        <div class="isbf-calendar-update-dialog__snapshot">
          <h3>{{i18n (themePrefix "isbf_v2.schedule_current")}}</h3>
          <strong>{{this.entry.title}}</strong>
          <p>{{this.currentTime}}</p>
          {{#if this.entry.note}}<p>{{this.entry.note}}</p>{{/if}}
        </div>
        <div class="isbf-calendar-update-dialog__latest">
          <h3>{{i18n (themePrefix "isbf_v2.schedule_latest")}}</h3>
          {{#if this.entry.cancelled}}
            <p>{{i18n (themePrefix "isbf_v2.schedule_cancelled_hint")}}</p>
          {{else if this.entry.source_unavailable}}
            <p>{{i18n (themePrefix "isbf_v2.schedule_unavailable")}}</p>
          {{else}}
            <strong>{{this.entry.latest_source.title}}</strong>
            <p>{{this.latestTime}}</p>
          {{/if}}
          {{#if this.entry.source_url}}<a href={{this.entry.source_url}}>{{i18n
                (themePrefix "isbf_v2.schedule_source")
              }}</a>{{/if}}
        </div>
        {{#if this.versionChanged}}<p role="status">{{i18n
              (themePrefix "isbf_v2.schedule_version_changed")
            }}</p>{{/if}}
        {{#if this.error}}<p
            class="isbf-calendar-update-dialog__error"
            role="alert"
          >{{i18n (themePrefix "isbf_v2.schedule_update_error")}}</p>{{/if}}
      </:body>
      <:footer>
        {{#if this.canAccept}}<DButton
            class="btn-primary isbf-calendar-update-dialog__accept"
            @action={{this.accept}}
            @disabled={{this.isSaving}}
            @label={{themePrefix "isbf_v2.schedule_accept"}}
          />{{/if}}
        {{#if this.entry.needs_update}}<DButton
            class="isbf-calendar-update-dialog__dismiss"
            @action={{this.dismiss}}
            @disabled={{this.isSaving}}
            @label={{themePrefix "isbf_v2.schedule_keep"}}
          />{{/if}}
        {{#if this.entry.cancelled}}<DButton
            class="btn-danger isbf-calendar-update-dialog__remove"
            @action={{this.remove}}
            @disabled={{this.isSaving}}
            @label={{themePrefix "isbf_v2.calendar_delete"}}
          />{{/if}}
      </:footer>
    </DModal>
  </template>
}
