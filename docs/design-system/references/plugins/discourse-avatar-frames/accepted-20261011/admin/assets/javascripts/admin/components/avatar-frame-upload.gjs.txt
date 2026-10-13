import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DPickFilesButton from "discourse/ui-kit/d-pick-files-button";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import { i18n } from "discourse-i18n";
import AvatarFrameOverlay from "discourse/plugins/discourse-avatar-frames/discourse/components/avatar-frame-overlay";

export default class AvatarFrameUpload extends Component {
  @service currentUser;

  @tracked uploading = false;
  @tracked uploadedUrl;
  @tracked uploadedStaticUrl;
  @tracked suggestedCalibration;

  get imageUrl() {
    return this.uploadedUrl || this.args.frame?.image_url;
  }

  get previewFrame() {
    return {
      key: "calibration-preview",
      image_url: this.imageUrl,
      static_url: this.uploadedStaticUrl || this.args.frame?.static_url,
      scale: this.args.data.scale,
      offset_x: this.args.data.offset_x,
      offset_y: this.args.data.offset_y,
    };
  }

  @action
  async adjust(value, { name, set }) {
    await set("confirm_calibration", false);
    await set(name, value);
  }

  @action
  reset() {
    return this.args.onUploaded({
      scale: 120,
      offset_x: 0,
      offset_y: 0,
      confirm_calibration: false,
    });
  }

  @action
  applySuggestion() {
    return this.args.onUploaded({
      ...this.suggestedCalibration,
      confirm_calibration: false,
    });
  }

  @action
  async upload(files) {
    if (this.uploading) {
      return;
    }
    this.uploading = true;
    try {
      const data = new FormData();
      data.append("file", files[0]);
      const result = await ajax("/avatar-frames/admin/uploads", {
        type: "POST",
        processData: false,
        contentType: false,
        data,
      });
      this.uploadedUrl = result.image_upload.url;
      this.uploadedStaticUrl = result.static_upload.url;
      this.suggestedCalibration = result.suggested_calibration;
      await this.args.onUploaded({
        image_upload_id: result.image_upload.id,
        static_upload_id: result.static_upload.id,
        scale: 120,
        offset_x: 0,
        offset_y: 0,
        confirm_calibration: false,
      });
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.uploading = false;
    }
  }

  <template>
    <div class="avatar-frame-admin__upload">
      {{#if this.imageUrl}}
        <div
          aria-label={{i18n "avatar_frames.admin.calibration"}}
          class="avatar-frame-calibration"
          role="group"
        >
          <div aria-hidden="true" class="avatar-frame-calibration__previews">
            <span class="avatar-frame-calibration__avatar --large">
              {{dAvatar this.currentUser imageSize="huge"}}
              <AvatarFrameOverlay @frame={{this.previewFrame}} />
            </span>
            <span class="avatar-frame-calibration__avatar --small">
              {{dAvatar this.currentUser imageSize="large"}}
              <AvatarFrameOverlay @frame={{this.previewFrame}} />
            </span>
          </div>
          <p>{{i18n "avatar_frames.admin.calibration_help"}}</p>
          <@form.Field
            @name="scale"
            @onSet={{this.adjust}}
            @title={{i18n "avatar_frames.admin.scale"}}
            @type="input-number"
            @validation="required|number|between:50,300"
            as |field|
          ><field.Control
              max="300"
              min="50"
              step="0.1"
              @after="%"
            /></@form.Field>
          <@form.Field
            @name="offset_x"
            @onSet={{this.adjust}}
            @title={{i18n "avatar_frames.admin.offset_x"}}
            @type="input-number"
            @validation="required|number|between:-100,100"
            as |field|
          ><field.Control
              max="100"
              min="-100"
              step="0.1"
              @after="%"
            /></@form.Field>
          <@form.Field
            @name="offset_y"
            @onSet={{this.adjust}}
            @title={{i18n "avatar_frames.admin.offset_y"}}
            @type="input-number"
            @validation="required|number|between:-100,100"
            as |field|
          ><field.Control
              max="100"
              min="-100"
              step="0.1"
              @after="%"
            /></@form.Field>
          <div class="avatar-frame-calibration__actions">
            <@form.Button
              @action={{this.reset}}
              @label="avatar_frames.admin.reset_calibration"
            />
            {{#if this.suggestedCalibration}}
              <@form.Button
                @action={{this.applySuggestion}}
                @label="avatar_frames.admin.apply_suggestion"
              />
            {{/if}}
          </div>
          <@form.Field
            @name="confirm_calibration"
            @title={{i18n "avatar_frames.admin.confirm_calibration"}}
            @type="checkbox"
            @validation={{if @data.enabled "accepted"}}
            as |field|
          ><field.Control /></@form.Field>
        </div>
      {{/if}}
      <DPickFilesButton
        @acceptedFormatsOverride=".png"
        @fileInputDisabled={{this.uploading}}
        @label="avatar_frames.admin.upload"
        @onFilesPicked={{this.upload}}
        @showButton={{true}}
      />
      {{#if this.uploading}}<span role="status">{{i18n
            "avatar_frames.admin.uploading"
          }}</span>{{/if}}
    </div>
  </template>
}
