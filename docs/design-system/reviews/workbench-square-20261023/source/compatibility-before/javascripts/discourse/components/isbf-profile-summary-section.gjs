import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat } from "@ember/helper";
import { action } from "@ember/object";
import { guidFor } from "@ember/object/internals";
import { LinkTo } from "@ember/routing";
import { themePrefix } from "virtual:theme";
import UserSummarySection from "discourse/components/user-summary-section";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class ISBFProfileSummarySection extends Component {
  @tracked expanded = false;

  listId = `isbf-summary-items-${guidFor(this)}`;

  get canExpand() {
    return this.items.length > 3;
  }

  get hasActions() {
    return this.canExpand || this.showActivityLink;
  }

  get items() {
    return this.args.items || [];
  }

  get showActivityLink() {
    return Boolean(this.args.moreRoute && this.items.length >= 6);
  }

  get toggleLabel() {
    return themePrefix(
      this.expanded ? "isbf_v2.summary_collapse" : "isbf_v2.summary_expand"
    );
  }

  get visibleItems() {
    return this.expanded ? this.items : this.items.slice(0, 3);
  }

  @action
  toggle() {
    this.expanded = !this.expanded;
  }

  <template>
    <UserSummarySection
      aria-label={{i18n (concat "user.summary." @title)}}
      class={{if
        @isUserList
        "isbf-profile-summary__section summary-user-list"
        "isbf-profile-summary__section"
      }}
      role="region"
      @title={{@title}}
    >
      {{#if this.items.length}}
        <ul id={{this.listId}}>
          {{#each this.visibleItems as |item|}}
            {{yield item}}
          {{/each}}
        </ul>
      {{else}}
        <p>{{i18n @emptyKey}}</p>
      {{/if}}

      {{#if this.hasActions}}
        <div class="isbf-profile-summary__actions">
          {{#if this.canExpand}}
            <DButton
              aria-controls={{this.listId}}
              aria-expanded={{this.expanded}}
              class="btn-flat isbf-profile-summary__toggle"
              @action={{this.toggle}}
              @label={{this.toggleLabel}}
            />
          {{/if}}
          {{#if this.showActivityLink}}
            <LinkTo
              class="isbf-profile-summary__more"
              @model={{@user}}
              @route={{@moreRoute}}
            >
              {{i18n @moreLabel}}
            </LinkTo>
          {{/if}}
        </div>
      {{/if}}
    </UserSummarySection>
  </template>
}
