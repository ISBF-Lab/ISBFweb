import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { trustHTML } from "@ember/template";
import { themePrefix } from "virtual:theme";
import FlagActionType from "discourse/components/flag-action-type";
import FlagSelection from "discourse/components/flag-selection";
import Flag from "discourse/components/modal/flag";
import PluginOutlet from "discourse/components/plugin-outlet";
import ReviewableBundledAction from "discourse/components/reviewable-bundled-action";
import lazyHash from "discourse/helpers/lazy-hash";
import { ajax } from "discourse/lib/ajax";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class ISBFFlagModal extends Flag {
  @tracked severeConfirmed = false;
  @tracked severeError = null;
  @tracked severeReason = "";
  @tracked severeStep = false;
  @tracked severeSubmitting = false;

  get canSevereReport() {
    return this.args.model.canSevereReport?.() === true;
  }

  get severeSubmitEnabled() {
    const length = [...this.severeReason.trim()].length;
    return (
      this.canSevereReport &&
      length >= 10 &&
      length <= 2000 &&
      this.severeConfirmed &&
      !this.severeSubmitting
    );
  }

  @action
  closeReporting() {
    if (!this.severeSubmitting) {
      this.args.closeModal();
    }
  }

  @action
  enterSevere() {
    if (this.canSevereReport) {
      this.severeStep = true;
    }
  }

  @action
  leaveSevere() {
    if (!this.severeSubmitting) {
      this.severeStep = false;
    }
  }

  @action
  handleReportingKeydown(event) {
    if (this.severeStep) {
      if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
        event.preventDefault();
        this.submitSevere();
      }
      return;
    }
    this.onKeydown(event);
  }

  @action
  updateConfirmation(event) {
    this.severeConfirmed = event.target.checked;
  }

  @action
  updateReason(event) {
    this.severeReason = event.target.value;
  }

  @action
  async submitSevere() {
    if (!this.severeSubmitEnabled) {
      return;
    }
    this.severeSubmitting = true;
    this.severeError = null;
    try {
      const post = this.args.model.flagModel;
      const result = await ajax("/isbf/moderation/severe-reports", {
        type: "POST",
        contentType: "application/json",
        data: JSON.stringify({
          post_id: post.id,
          reason: this.severeReason.trim(),
          confirmed: true,
        }),
      });
      if (
        Number(result.post_id) !== Number(post.id) ||
        result.hidden !== true
      ) {
        throw new Error("Unexpected severe report response");
      }
      post.setProperties({ cooked: "", isbf_severe_report_pending: true });
      this.args.model.setHidden();
      this.args.closeModal();
    } catch (error) {
      this.severeError =
        error?.jqXHR?.responseJSON?.errors?.[0] ||
        i18n(themePrefix("isbf_v2.severe_failed"));
    } finally {
      this.severeSubmitting = false;
    }
  }

  <template>
    <DModal
      class="flag-modal isbf-flag-modal"
      @bodyClass="flag-modal-body"
      @closeModal={{this.closeReporting}}
      @dismissable={{not this.severeSubmitting}}
      @submitOnEnter={{false}}
      @title={{i18n this.title}}
      {{on "keydown" this.handleReportingKeydown}}
    >
      <:body>
        {{#if this.severeStep}}
          <p>{{i18n (themePrefix "isbf_v2.severe_description")}}</p>
          <label for="isbf-severe-reason">{{i18n
              (themePrefix "isbf_v2.severe_reason")
            }}</label>
          <textarea
            aria-describedby="isbf-severe-hint"
            disabled={{this.severeSubmitting}}
            id="isbf-severe-reason"
            value={{this.severeReason}}
            {{on "input" this.updateReason}}
          ></textarea>
          <p class="isbf-flag-modal__hint" id="isbf-severe-hint">{{i18n
              (themePrefix "isbf_v2.severe_hint")
            }}</p>
          <label class="isbf-flag-modal__confirmation">
            <input
              checked={{this.severeConfirmed}}
              disabled={{this.severeSubmitting}}
              type="checkbox"
              {{on "change" this.updateConfirmation}}
            />
            {{i18n (themePrefix "isbf_v2.severe_confirm")}}
          </label>
          {{#if this.severeError}}<p
              class="isbf-flag-modal__error"
              role="alert"
            >{{this.severeError}}</p>{{/if}}
        {{/if}}
        <div hidden={{this.severeStep}}>
          <p>{{trustHTML (i18n "flagging.review_process_description")}}</p>
          <PluginOutlet
            @connectorTagName="div"
            @name="after-flag-modal-review-process-description"
            @outletArgs={{lazyHash post=@model.flagModel}}
          />
          <form>
            <FlagSelection
              @flags={{this.flagsAvailable}}
              @nameKey={{this.selected.name_key}}
              as |f|
            >
              <FlagActionType
                @changePostActionType={{this.changePostActionType}}
                @flag={{f}}
                @isConfirmed={{this.isConfirmed}}
                @message={{this.message}}
                @selectedFlag={{this.selected}}
                @staffFlagsAvailable={{this.staffFlagsAvailable}}
                @username={{@model.flagModel.username}}
              />
            </FlagSelection>
          </form>
          <PluginOutlet
            @connectorTagName="div"
            @name="flag-modal-bottom"
            @outletArgs={{lazyHash post=@model.flagModel}}
          />
        </div>
      </:body>
      <:footer>
        {{#if this.severeStep}}
          <DButton
            class="btn-danger isbf-flag-modal__severe"
            @action={{this.submitSevere}}
            @disabled={{not this.severeSubmitEnabled}}
            @label={{themePrefix "isbf_v2.severe_submit"}}
            @loading={{this.severeSubmitting}}
          />
          <DButton
            @action={{this.leaveSevere}}
            @disabled={{this.severeSubmitting}}
            @label={{themePrefix "isbf_v2.severe_back"}}
          />
        {{else}}
          <DButton
            class="btn-primary flag-modal__create-flag"
            @action={{this.createFlag}}
            @disabled={{not this.submitEnabled}}
            @icon={{if this.selected.require_message "envelope" "flag"}}
            @label={{this.submitLabel}}
            @title="flagging.submit_tooltip"
          />
          {{#if this.canSevereReport}}
            <DButton
              class="btn-danger isbf-flag-modal__severe"
              @action={{this.enterSevere}}
              @icon="triangle-exclamation"
              @label={{themePrefix "isbf_v2.severe_report"}}
            />
          {{/if}}
          {{#if this.canSendWarning}}
            <DButton
              class="btn-danger flag-modal__send-warning"
              @action={{this.createFlagAsWarning}}
              @disabled={{not this.submitEnabled}}
              @icon="triangle-exclamation"
              @label="flagging.official_warning"
            />
          {{/if}}
          {{#if this.canTakeAction}}
            <ReviewableBundledAction
              class="flag-modal__take-action"
              @bundle={{this.flagActions}}
              @performAction={{this.takeAction}}
              @reviewableUpdating={{not this.submitEnabled}}
            />
            <DButton
              class="btn-danger flag-modal__flag-for-review"
              @action={{this.flagForReview}}
              @disabled={{not this.submitEnabled}}
              @icon="triangle-exclamation"
              @label="flagging.flag_for_review"
            />
          {{/if}}
          {{#if this.showDeleteSpammer}}
            <DButton
              class="btn-danger delete-spammer flag-modal__delete-spammer"
              @action={{this.deleteSpammer}}
              @disabled={{not this.submitEnabled}}
              @icon="triangle-exclamation"
              @label="flagging.delete_spammer"
            />
          {{/if}}
        {{/if}}
      </:footer>
    </DModal>
  </template>
}
