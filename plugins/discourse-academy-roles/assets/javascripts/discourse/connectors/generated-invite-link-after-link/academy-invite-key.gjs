import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class AcademyInviteKey extends Component {
  @service currentUser;
  @service siteSettings;

  get showCode() {
    return this.siteSettings.academy_roles_enabled && this.currentUser?.admin;
  }

  get code() {
    return new URL(this.args.outletArgs.link, window.location.origin).pathname
      .split("/")
      .at(-1);
  }

  @action
  copyCode() {
    navigator.clipboard.writeText(this.code);
  }

  <template>
    {{#if this.showCode}}
      <div class="academy-invite-key" ...attributes>
        <label for="academy-invite-key">{{i18n
            "academy_roles.invite_code"
          }}</label>
        <input
          id="academy-invite-key"
          readonly
          type="text"
          value={{this.code}}
        />
        <DButton
          @action={{this.copyCode}}
          @icon="copy"
          @label="academy_roles.copy_code"
        />
      </div>
    {{/if}}
  </template>
}
