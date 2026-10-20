import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { optionalTopicTitle } from "../lib/optional-topic-title";
import ISBFPostPreview from "./isbf-post-preview";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
export default class ISBFSummaryTopicTitle extends Component {
  get disabled() {
    const topic = this.args.outletArgs.topic;
    return topic.hidden || topic.deleted;
  }
  get titled() {
    return Boolean(optionalTopicTitle(this.args.outletArgs.topic.title).trim());
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
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
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"titled\"]],[[[1,\"  \"],[11,3],[16,6,[30,1,[\"url\"]]],[17,2],[12],[1,[28,[32,0],[[30,1,[\"topic\",\"fancyTitle\"]]],null]],[13],[1,\"\\n\"]],[]],[[[1,\"  \"],[8,[32,1],[[17,2]],[[\"@disabled\",\"@href\",\"@postNumber\",\"@title\",\"@topicId\",\"@variant\"],[[30,0,[\"disabled\"]],[30,1,[\"url\"]],[30,1,[\"postNumber\"]],[30,1,[\"topic\",\"title\"]],[30,1,[\"topic\",\"id\"]],\"summary\"]],null],[1,\"\\n\"]],[]]]],[\"@outletArgs\",\"&attrs\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        trustHTML,
        ISBFPostPreview
      }),
      "isStrictMode": true
    }), this);
  }
}