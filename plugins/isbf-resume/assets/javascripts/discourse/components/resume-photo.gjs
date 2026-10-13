import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class ResumePhoto extends Component {
  @service a11y;

  @tracked busy = false;
  @tracked error = null;
  #selection = 0;

  willDestroy() {
    super.willDestroy();
    this.#selection++;
    this.args.onBusy?.(false);
  }

  get errorId() {
    return `${this.args.id}-photo-error`;
  }

  get invalid() {
    return Boolean(this.error || this.args.invalid);
  }

  get describedBy() {
    return [this.args.describedBy, this.error ? this.errorId : null]
      .filter(Boolean)
      .join(" ");
  }

  @action
  async selectPhoto(event) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) {
      return;
    }
    const selection = ++this.#selection;
    this.error = null;
    if (!/^image\/(jpeg|png|webp)$/.test(file.type) || file.size > 5242880) {
      this.busy = false;
      this.args.onBusy?.(false);
      this.error = i18n("isbf_resume.photo_invalid");
      this.a11y.announce(this.error, "assertive");
      return;
    }
    this.busy = true;
    this.args.onBusy?.(true);
    try {
      const bitmap = await createImageBitmap(file);
      const pixels = bitmap.width * bitmap.height;
      bitmap.close();
      if (pixels > 16000000) {
        throw new Error("dimensions");
      }
      const value = await new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = reject;
        reader.readAsDataURL(file);
      });
      if (!this.isDestroying && selection === this.#selection) {
        await this.args.onChange(value);
        this.a11y.announce(i18n("isbf_resume.photo_ready"));
      }
    } catch {
      if (!this.isDestroying && selection === this.#selection) {
        this.error = i18n("isbf_resume.photo_invalid");
        this.a11y.announce(this.error, "assertive");
      }
    } finally {
      if (!this.isDestroying && selection === this.#selection) {
        this.busy = false;
        this.args.onBusy?.(false);
      }
    }
  }

  @action
  removePhoto() {
    this.#selection++;
    this.error = null;
    this.busy = false;
    this.args.onBusy?.(false);
    this.args.onChange("");
  }

  <template>
    <div class="isbf-resume-photo isbf-resume__photo">
      {{#if @value}}
        <img
          alt={{i18n "isbf_resume.fields.basic.photo.label"}}
          src={{@value}}
        />
        <DButton
          @action={{this.removePhoto}}
          @disabled={{@disabled}}
          @label="isbf_resume.photo_remove"
        />
      {{/if}}
      <input
        accept="image/jpeg,image/png,image/webp"
        aria-describedby={{this.describedBy}}
        aria-invalid={{if this.invalid "true"}}
        disabled={{@disabled}}
        id={{@id}}
        type="file"
        {{on "change" this.selectPhoto}}
      />
      {{#if this.busy}}<p>{{i18n "isbf_resume.photo_reading"}}</p>{{/if}}
      {{#if this.error}}<p
          class="isbf-resume__error"
          id={{this.errorId}}
        >{{this.error}}</p>{{/if}}
    </div>
  </template>
}
