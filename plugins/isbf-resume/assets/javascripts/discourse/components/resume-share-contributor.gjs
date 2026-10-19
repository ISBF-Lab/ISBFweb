import Component from "@glimmer/component";
import DUserLink from "discourse/ui-kit/d-user-link";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import { i18n } from "discourse-i18n";

export default class ResumeShareContributor extends Component {
  get label() {
    return (
      this.args.share.contributor ||
      this.args.share.contributor_user?.name ||
      this.args.share.contributor_user?.username
    );
  }

  <template>
    {{#if this.label}}
      <span class="isbf-resume-share-contributor" ...attributes>
        <span>{{i18n "isbf_resume.sharing.contributor_credit"}}</span>
        {{#if @share.contributor_user}}
          <DUserLink @user={{@share.contributor_user}}>
            {{dAvatar @share.contributor_user imageSize="tiny"}}
            {{this.label}}
          </DUserLink>
        {{else}}
          <span>{{this.label}}</span>
        {{/if}}
      </span>
    {{/if}}
  </template>
}
