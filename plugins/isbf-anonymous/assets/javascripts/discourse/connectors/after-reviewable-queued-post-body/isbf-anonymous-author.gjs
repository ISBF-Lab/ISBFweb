import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/ui-kit/d-button";
import IsbfAnonymousAuthor from "../../components/modal/isbf-anonymous-author";

export default class IsbfAnonymousAuthorButton extends Component {
  @service currentUser;
  @service modal;

  get canLookupAuthor() {
    return (
      this.currentUser?.admin &&
      this.args.outletArgs.model.isbf_per_post_anonymous
    );
  }

  @action
  lookupAuthor() {
    this.modal.show(IsbfAnonymousAuthor, {
      model: { id: this.args.outletArgs.model.id, type: "queued-posts" },
    });
  }

  <template>
    {{#if this.canLookupAuthor}}
      <DButton
        class="btn-default isbf-anonymous-author-lookup"
        @action={{this.lookupAuthor}}
        @icon="user"
        @label="isbf_anonymous.author_lookup.button"
      />
    {{/if}}
  </template>
}
