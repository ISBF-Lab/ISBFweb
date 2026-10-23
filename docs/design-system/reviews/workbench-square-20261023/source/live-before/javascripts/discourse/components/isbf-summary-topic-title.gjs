import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { optionalTopicTitle } from "../lib/optional-topic-title";
import ISBFPostPreview from "./isbf-post-preview";

export default class ISBFSummaryTopicTitle extends Component {
  get disabled() {
    const topic = this.args.outletArgs.topic;
    return topic.hidden || topic.deleted;
  }

  get titled() {
    return Boolean(optionalTopicTitle(this.args.outletArgs.topic.title).trim());
  }

  <template>
    {{#if this.titled}}
      <a href={{@outletArgs.url}} ...attributes>{{trustHTML
          @outletArgs.topic.fancyTitle
        }}</a>
    {{else}}
      <ISBFPostPreview
        ...attributes
        @disabled={{this.disabled}}
        @href={{@outletArgs.url}}
        @postNumber={{@outletArgs.postNumber}}
        @title={{@outletArgs.topic.title}}
        @topicId={{@outletArgs.topic.id}}
        @variant="summary"
      />
    {{/if}}
  </template>
}
