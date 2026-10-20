import Component from "@glimmer/component";
import { cached } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import BackButton from "discourse/components/back-button";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DBreadcrumbsItem from "discourse/ui-kit/d-breadcrumbs-item";
import { i18n } from "discourse-i18n";
import AvatarFrameUpload from "./avatar-frame-upload";

export default class AvatarFrameForm extends Component {
  @service router;
  @service site;

  @cached
  get formData() {
    const frame = this.args.frame;
    return {
      name: frame?.name || "",
      description: frame?.description || "",
      access_mode: frame?.access_mode || "granted",
      enabled: frame?.enabled ?? true,
      position: frame?.position || 0,
      image_upload_id: frame?.image_upload_id,
      static_upload_id: frame?.static_upload_id,
      scale: frame?.scale ?? 120,
      offset_x: frame?.offset_x ?? 0,
      offset_y: frame?.offset_y ?? 0,
      confirm_calibration: frame?.calibration_confirmed ?? false,
    };
  }

  get title() {
    return this.args.frame
      ? "avatar_frames.admin.edit"
      : "avatar_frames.admin.new";
  }

  @action
  async save(data) {
    try {
      const id = this.args.frame?.id;
      await ajax(`/avatar-frames/admin/frames${id ? `/${id}` : ""}`, {
        type: id ? "PUT" : "POST",
        data,
      });
      const catalog = await ajax("/site.json");
      this.site.set("avatar_frames", catalog.avatar_frames);
      this.router.transitionTo("adminPlugins.show.avatar-frames.index");
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <DBreadcrumbsItem
      @label={{i18n "avatar_frames.admin.frames"}}
      @route="adminPlugins.show.avatar-frames"
    />
    <DBreadcrumbsItem @label={{i18n this.title}} />
    <BackButton @route="adminPlugins.show.avatar-frames" />
    <div class="avatar-frame-admin">
      <AdminConfigAreaCard @heading={{this.title}}>
        <:content>
          <Form @data={{this.formData}} @onSubmit={{this.save}} as |form data|>
            <form.Field
              @name="name"
              @title={{i18n "avatar_frames.admin.name"}}
              @type="input"
              @validation="required|length:1,100"
              as |field|
            ><field.Control /></form.Field>
            <form.Field
              @name="description"
              @title={{i18n "avatar_frames.admin.frame_description"}}
              @type="textarea"
              @validation="length:0,500"
              as |field|
            ><field.Control /></form.Field>
            <form.Field
              @description={{i18n "avatar_frames.admin.image_help"}}
              @name="image_upload_id"
              @title={{i18n "avatar_frames.admin.image"}}
              @type="custom"
              @validation={{unless @frame "required"}}
              as |field|
            >
              <field.Control><AvatarFrameUpload
                  @data={{data}}
                  @form={{form}}
                  @frame={{@frame}}
                  @onUploaded={{form.setProperties}}
                /></field.Control>
            </form.Field>
            <form.Field
              @name="access_mode"
              @title={{i18n "avatar_frames.admin.access"}}
              @type="select"
              as |field|
            >
              <field.Control @includeNone={{false}} as |select|>
                <select.Option @value="granted">{{i18n
                    "avatar_frames.admin.granted"
                  }}</select.Option>
                <select.Option @value="public">{{i18n
                    "avatar_frames.admin.public"
                  }}</select.Option>
              </field.Control>
            </form.Field>
            <form.Field
              @name="position"
              @title={{i18n "avatar_frames.admin.position"}}
              @type="input-number"
              as |field|
            ><field.Control min="0" /></form.Field>
            <form.Field
              @name="enabled"
              @title={{i18n "avatar_frames.admin.enabled"}}
              @type="checkbox"
              as |field|
            ><field.Control /></form.Field>
            <form.Submit @label="save" />
          </Form>
        </:content>
      </AdminConfigAreaCard>
    </div>
  </template>
}
