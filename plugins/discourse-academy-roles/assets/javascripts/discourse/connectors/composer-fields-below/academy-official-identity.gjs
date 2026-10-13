import Component from "@glimmer/component";
import { action, set } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { and, not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class AcademyOfficialIdentity extends Component {
  @service currentUser;
  @service siteSettings;

  get model() {
    return this.args.outletArgs.model;
  }

  get isOfficialCategory() {
    if (!Number(this.siteSettings.academy_official_category)) {
      return false;
    }

    return (
      Number(this.model.categoryId || this.model.topic?.category?.id) ===
      Number(this.siteSettings.academy_official_category)
    );
  }

  get canUseOfficialIdentity() {
    return this.currentUser?.academy_official_member && this.isOfficialCategory;
  }

  get switchLabel() {
    return this.model.academyOfficial
      ? "academy_roles.post_as_member"
      : "academy_roles.post_as_official";
  }

  get identityLabel() {
    return this.model.academyOfficial
      ? "academy_roles.posting_as_official"
      : "academy_roles.posting_as_member";
  }

  @action
  syncCategory() {
    if (!this.canUseOfficialIdentity) {
      set(this.model, "academyOfficial", false);
    } else if (this.model.creatingTopic) {
      set(this.model, "academyOfficial", true);
    }
  }

  @action
  toggleIdentity() {
    set(this.model, "academyOfficial", !this.model.academyOfficial);
  }

  <template>
    {{#if this.siteSettings.academy_roles_enabled}}
      <div
        class="academy-official-identity"
        ...attributes
        {{didInsert this.syncCategory}}
        {{didUpdate this.syncCategory this.model.categoryId}}
      >
        {{#if (and this.canUseOfficialIdentity (not this.model.editingPost))}}
          {{#if this.model.creatingTopic}}
            <span>{{i18n "academy_roles.official_topic"}}</span>
          {{else}}
            <span class="academy-official-identity__status">
              {{i18n this.identityLabel}}
            </span>
            <DButton
              aria-pressed={{this.model.academyOfficial}}
              @action={{this.toggleIdentity}}
              @label={{this.switchLabel}}
            />
          {{/if}}
        {{/if}}
      </div>
    {{/if}}
  </template>
}
