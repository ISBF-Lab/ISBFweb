import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { DNativeSelectOption } from "discourse/ui-kit/d-native-select";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import { i18n } from "discourse-i18n";
import AvatarFrameOverlay from "../../components/avatar-frame-overlay";
import { availableFrames } from "../../lib/avatar-frames";

export default class AvatarFramePreferences extends Component {
  @service currentUser;
  @service site;
  @service siteSettings;

  get previewUser() {
    const model = this.args.outletArgs.model;
    return model.id === this.currentUser?.id ? this.currentUser : model;
  }

  get formData() {
    return {
      avatar_frame:
        this.args.outletArgs.model.custom_fields?.avatar_frame || "none",
    };
  }

  get frames() {
    return [
      { id: "none", name: i18n("avatar_frames.none") },
      ...availableFrames(
        this.site.avatar_frames,
        this.args.outletArgs.model.available_avatar_frames
      ),
    ];
  }

  @action
  setFrame(name, value) {
    const model = this.args.outletArgs.model;
    model.set("custom_fields", {
      ...model.custom_fields,
      avatar_frame: value === "none" ? null : value,
    });
  }

  <template>
    {{#if this.siteSettings.avatar_frames_enabled}}
      <Form
        class="avatar-frame-preferences"
        @data={{this.formData}}
        @onSet={{this.setFrame}}
        @onSubmit={{@outletArgs.save}}
        as |form|
      >
        <form.Field
          @description={{i18n "avatar_frames.instructions"}}
          @name="avatar_frame"
          @title={{i18n "avatar_frames.title"}}
          @type="select"
          as |field|
        >
          <div class="avatar-frame-preferences__selection">
            <span aria-hidden="true" class="avatar-frame-preferences__preview">
              {{dAvatar this.previewUser imageSize="large"}}
              <AvatarFrameOverlay @frame={{field.value}} @motion="static" />
            </span>
            <field.Control @includeNone={{false}}>
              {{#each this.frames as |frame|}}
                <DNativeSelectOption
                  @selected={{field.value}}
                  @value={{frame.id}}
                >
                  {{frame.name}}
                </DNativeSelectOption>
              {{/each}}
            </field.Control>
          </div>
        </form.Field>
      </Form>
    {{/if}}
  </template>
}
