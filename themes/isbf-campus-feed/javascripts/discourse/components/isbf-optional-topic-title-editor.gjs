import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DTextField from "discourse/ui-kit/d-text-field";
import dAutoFocus from "discourse/ui-kit/modifiers/d-auto-focus";
import {
  isUntitledTopicTitle,
  optionalTopicTitle,
} from "../lib/optional-topic-title";

export default class ISBFOptionalTopicTitleEditor extends Component {
  @service siteSettings;

  @tracked
  value = optionalTopicTitle(this.args.outletArgs.buffered.get("title"));

  get enabled() {
    return (
      isUntitledTopicTitle(this.args.outletArgs.model.title) &&
      !this.args.outletArgs.model.fancy_title_localized
    );
  }

  @action
  update(event) {
    this.value = event.target.value;
    this.args.outletArgs.buffered.set(
      "title",
      this.value.trim() ? this.value : this.args.outletArgs.model.title
    );
  }

  <template>
    {{#if this.enabled}}
      <DTextField
        @autofocus={{true}}
        @id="edit-title"
        @maxlength={{this.siteSettings.max_topic_title_length}}
        @value={{this.value}}
        {{dAutoFocus}}
        {{on "input" this.update}}
      />
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
