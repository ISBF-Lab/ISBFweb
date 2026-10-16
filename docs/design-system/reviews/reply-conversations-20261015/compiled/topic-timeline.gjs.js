import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { modifier } from "ember-modifier";
import Container from "discourse/components/topic-timeline/container";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class TopicTimeline extends Component {
  static {
    g(this.prototype, "docked", [tracked], function () {
      return false;
    });
  }
  #docked = (i(this, "docked"), void 0);
  static {
    g(this.prototype, "dockedBottom", [tracked], function () {
      return false;
    });
  }
  #dockedBottom = (i(this, "dockedBottom"), void 0);
  enteredIndex = this.args.prevEvent ? this.args.prevEvent.postIndex - 1 : this.args.enteredIndex;
  addShowClass = modifier(el => {
    if (this.args.fullscreen) {
      el.classList.add("show");
    }
  });
  setDocked(value) {
    if (this.docked !== value) {
      this.docked = value;
    }
  }
  static {
    n(this.prototype, "setDocked", [action]);
  }
  setDockedBottom(value) {
    if (this.dockedBottom !== value) {
      this.dockedBottom = value;
    }
  }
  static {
    n(this.prototype, "setDockedBottom", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <div
      class={{dConcatClass
        "timeline-container"
        (if @fullscreen "timeline-fullscreen")
        (if this.docked "timeline-docked")
        (if this.dockedBottom "timeline-docked-bottom")
      }}
      {{this.addShowClass}}
    >
      <div class="topic-timeline">
        <Container
          @convertToPrivateMessage={{@convertToPrivateMessage}}
          @convertToPublicTopic={{@convertToPublicTopic}}
          @deleteTopic={{@deleteTopic}}
          @enteredIndex={{this.enteredIndex}}
          @fullscreen={{@fullscreen}}
          @jumpBottom={{@jumpBottom}}
          @jumpEnd={{@jumpEnd}}
          @jumpToIndex={{@jumpToIndex}}
          @jumpTop={{@jumpTop}}
          @jumpToPostPrompt={{@jumpToPostPrompt}}
          @model={{@model}}
          @navigation={{@navigation}}
          @recoverTopic={{@recoverTopic}}
          @replyToPost={{@replyToPost}}
          @resetBumpDate={{@resetBumpDate}}
          @setDocked={{this.setDocked}}
          @setDockedBottom={{this.setDockedBottom}}
          @showChangeTimestamp={{@showChangeTimestamp}}
          @showFeatureTopic={{@showFeatureTopic}}
          @showTopicSlowModeUpdate={{@showTopicSlowModeUpdate}}
          @showTopicTimerModal={{@showTopicTimerModal}}
          @showTopReplies={{@showTopReplies}}
          @toggleArchived={{@toggleArchived}}
          @toggleClosed={{@toggleClosed}}
          @toggleMultiSelect={{@toggleMultiSelect}}
          @toggleVisibility={{@toggleVisibility}}
        />
      </div>
    </div>
    */
    {
      "id": null,
      "block": "[[[11,0],[16,0,[28,[32,0],[\"timeline-container\",[52,[30,1],\"timeline-fullscreen\"],[52,[30,0,[\"docked\"]],\"timeline-docked\"],[52,[30,0,[\"dockedBottom\"]],\"timeline-docked-bottom\"]],null]],[4,[30,0,[\"addShowClass\"]],null,null],[12],[1,\"\\n  \"],[10,0],[14,0,\"topic-timeline\"],[12],[1,\"\\n    \"],[8,[32,1],null,[[\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deleteTopic\",\"@enteredIndex\",\"@fullscreen\",\"@jumpBottom\",\"@jumpEnd\",\"@jumpToIndex\",\"@jumpTop\",\"@jumpToPostPrompt\",\"@model\",\"@navigation\",\"@recoverTopic\",\"@replyToPost\",\"@resetBumpDate\",\"@setDocked\",\"@setDockedBottom\",\"@showChangeTimestamp\",\"@showFeatureTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@showTopReplies\",\"@toggleArchived\",\"@toggleClosed\",\"@toggleMultiSelect\",\"@toggleVisibility\"],[[30,2],[30,3],[30,4],[30,0,[\"enteredIndex\"]],[30,1],[30,5],[30,6],[30,7],[30,8],[30,9],[30,10],[30,11],[30,12],[30,13],[30,14],[30,0,[\"setDocked\"]],[30,0,[\"setDockedBottom\"]],[30,15],[30,16],[30,17],[30,18],[30,19],[30,20],[30,21],[30,22],[30,23]]],null],[1,\"\\n  \"],[13],[1,\"\\n\"],[13]],[\"@fullscreen\",\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deleteTopic\",\"@jumpBottom\",\"@jumpEnd\",\"@jumpToIndex\",\"@jumpTop\",\"@jumpToPostPrompt\",\"@model\",\"@navigation\",\"@recoverTopic\",\"@replyToPost\",\"@resetBumpDate\",\"@showChangeTimestamp\",\"@showFeatureTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@showTopReplies\",\"@toggleArchived\",\"@toggleClosed\",\"@toggleMultiSelect\",\"@toggleVisibility\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        dConcatClass,
        Container
      }),
      "isStrictMode": true
    }), this);
  }
}