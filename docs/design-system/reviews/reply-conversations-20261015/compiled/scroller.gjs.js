import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { SCROLLER_HEIGHT, timelineDate } from "discourse/components/topic-timeline/container";
import { and, not } from "discourse/truth-helpers";
import dPointerDrag from "discourse/ui-kit/modifiers/d-pointer-drag";
import { i18n } from "discourse-i18n";
import BackButton from "./back-button";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
export default class TopicTimelineScroller extends Component {
  style = trustHTML(`height: ${SCROLLER_HEIGHT}px`);
  get repliesShort() {
    if (this.args.translatedLabel) {
      return this.args.translatedLabel;
    }
    return i18n(`topic.timeline.replies_short`, {
      current: this.args.current,
      total: this.args.total
    });
  }
  get timelineAgo() {
    return timelineDate(this.args.date);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class="timeline-scroller"
      style={{this.style}}
      ...attributes
      {{! Position is committed continuously as the pointer moves, so discarding
          on cancel would snap the topic back to where the drag began. }}
      {{dPointerDrag
        onDragStart=@didStartDrag
        onDrag=@dragMove
        onDragEnd=@didEndDrag
        cancelCommits=true
        bodyClass="dragging"
      }}
    >
      {{#if @fullscreen}}
        <div class="timeline-scroller-content">
          <div class="timeline-replies">
            {{this.repliesShort}}
          </div>
          {{#if @date}}
            <div class="timeline-ago">
              {{this.timelineAgo}}
            </div>
          {{/if}}
          {{#if (and @showDockedButton (not @dragging))}}
            <BackButton @onGoBack={{@onGoBack}} />
          {{/if}}
        </div>
        <div class="timeline-handle"></div>
      {{else}}
        <div class="timeline-handle"></div>
        <div class="timeline-scroller-content">
          <div class="timeline-replies">
            {{this.repliesShort}}
          </div>
          {{#if @date}}
            <div class="timeline-ago">
              {{this.timelineAgo}}
            </div>
          {{/if}}
          {{#if (and @showDockedButton (not @dragging))}}
            <BackButton @onGoBack={{@onGoBack}} />
          {{/if}}
        </div>
      {{/if}}
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[24,0,\"timeline-scroller\"],[16,5,[30,0,[\"style\"]]],[17,1],[4,[32,0],null,[[\"onDragStart\",\"onDrag\",\"onDragEnd\",\"cancelCommits\",\"bodyClass\"],[[30,2],[30,3],[30,4],true,\"dragging\"]]],[12],[1,\"\\n\"],[41,[30,5],[[[1,\"    \"],[10,0],[14,0,\"timeline-scroller-content\"],[12],[1,\"\\n      \"],[10,0],[14,0,\"timeline-replies\"],[12],[1,\"\\n        \"],[1,[30,0,[\"repliesShort\"]]],[1,\"\\n      \"],[13],[1,\"\\n\"],[41,[30,6],[[[1,\"        \"],[10,0],[14,0,\"timeline-ago\"],[12],[1,\"\\n          \"],[1,[30,0,[\"timelineAgo\"]]],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[41,[28,[32,1],[[30,7],[28,[32,2],[[30,8]],null]],null],[[[1,\"        \"],[8,[32,3],null,[[\"@onGoBack\"],[[30,9]]],null],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n    \"],[10,0],[14,0,\"timeline-handle\"],[12],[13],[1,\"\\n\"]],[]],[[[1,\"    \"],[10,0],[14,0,\"timeline-handle\"],[12],[13],[1,\"\\n    \"],[10,0],[14,0,\"timeline-scroller-content\"],[12],[1,\"\\n      \"],[10,0],[14,0,\"timeline-replies\"],[12],[1,\"\\n        \"],[1,[30,0,[\"repliesShort\"]]],[1,\"\\n      \"],[13],[1,\"\\n\"],[41,[30,6],[[[1,\"        \"],[10,0],[14,0,\"timeline-ago\"],[12],[1,\"\\n          \"],[1,[30,0,[\"timelineAgo\"]]],[1,\"\\n        \"],[13],[1,\"\\n\"]],[]],null],[41,[28,[32,1],[[30,7],[28,[32,2],[[30,8]],null]],null],[[[1,\"        \"],[8,[32,3],null,[[\"@onGoBack\"],[[30,9]]],null],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n\"]],[]]],[13]],[\"&attrs\",\"@didStartDrag\",\"@dragMove\",\"@didEndDrag\",\"@fullscreen\",\"@date\",\"@showDockedButton\",\"@dragging\",\"@onGoBack\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dPointerDrag,
        and,
        not,
        BackButton
      }),
      "isStrictMode": true
    }), this);
  }
}