import Component from "@glimmer/component";
import { array } from "@ember/helper";
import { service } from "@ember/service";
import AcademyOfficialPostQuota from "discourse/plugins/discourse-academy-roles/discourse/components/academy-official-post-quota";

export default class AcademyOfficialPostQuotaConnector extends Component {
  @service currentUser;
  @service siteSettings;

  get visible() {
    return (
      this.currentUser?.admin &&
      this.siteSettings.academy_roles_enabled &&
      this.args.outletArgs.user?.id > 0
    );
  }

  <template>
    {{#if this.visible}}
      {{#each (array @outletArgs.user) key="id" as |user|}}
        <AcademyOfficialPostQuota @user={{user}} />
      {{/each}}
    {{/if}}
  </template>
}
