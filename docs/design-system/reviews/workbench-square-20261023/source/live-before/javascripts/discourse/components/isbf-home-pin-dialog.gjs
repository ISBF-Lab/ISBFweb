import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import DFutureDateInput from "discourse/ui-kit/d-future-date-input";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import { pinDeadline, pinningMeta, saveHomePin } from "../lib/pinning";

export default class ISBFHomePinDialog extends Component {
  @tracked errorMessage = null;
  @tracked isSubmitting = false;
  @tracked until;

  #closed = false;

  constructor() {
    super(...arguments);
    const metadata = pinningMeta(this.args.model.topic);
    this.until = metadata?.active
      ? metadata.pinned_until
      : new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#closed = true;
  }

  get title() {
    return i18n(
      themePrefix(
        pinningMeta(this.args.model.topic)?.active
          ? "isbf_v2.pin_update"
          : "isbf_v2.pin",
      ),
    );
  }

  get submitDisabled() {
    return this.isSubmitting;
  }

  @action
  close() {
    this.#closed = true;
    this.args.closeModal();
  }

  @action
  updateUntil(value) {
    if (!this.isSubmitting && !this.#closed) {
      this.until = value;
      this.errorMessage = null;
    }
  }

  @action
  async submit(event) {
    event?.preventDefault();
    if (this.#closed || this.isSubmitting) {
      return;
    }
    const timestamp = pinDeadline(this.until)?.getTime() ?? NaN;
    if (!Number.isFinite(timestamp) || timestamp <= Date.now()) {
      this.errorMessage = i18n(themePrefix("isbf_v2.pin_validation"));
      return;
    }
    this.errorMessage = null;
    this.isSubmitting = true;
    try {
      const metadata = await saveHomePin(this.args.model.topic, {
        enabled: true,
        until: new Date(timestamp).toISOString(),
      });
      if (this.#closed || this.isDestroying) {
        return;
      }
      this.args.model.onSaved?.(metadata);
      this.close();
    } catch (error) {
      if (!this.#closed && !this.isDestroying) {
        this.errorMessage =
          error?.jqXHR?.responseJSON?.errors?.[0] ||
          error?.jqXHR?.responseJSON?.error ||
          i18n(themePrefix("isbf_v2.pin_error"));
      }
    } finally {
      if (!this.#closed && !this.isDestroying) {
        this.isSubmitting = false;
      }
    }
  }

  <template>
    <DModal
      class="isbf-home-pin-dialog"
      @closeModal={{this.close}}
      @submitOnEnter={{false}}
      @title={{this.title}}
    >
      <:body>
        <form {{on "submit" this.submit}}>
          <fieldset
            class="isbf-home-pin-dialog__field"
            disabled={{this.isSubmitting}}
          >
            <legend>{{i18n (themePrefix "isbf_v2.pin_until")}}</legend>
            <DFutureDateInput
              @clearable={{false}}
              @includeDateTime={{true}}
              @input={{this.until}}
              @noRelativeOptions={{true}}
              @onChangeInput={{this.updateUntil}}
            />
          </fieldset>
          {{#if this.errorMessage}}
            <p
              class="isbf-home-pin-dialog__error"
              role="alert"
            >{{this.errorMessage}}</p>
          {{/if}}
          <div class="isbf-home-pin-dialog__actions">
            <DButton @action={{this.close}} @label="cancel" />
            <DButton
              class="btn-primary"
              @disabled={{this.submitDisabled}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.pin_save")}}
              @type="submit"
            />
          </div>
        </form>
      </:body>
    </DModal>
  </template>
}
