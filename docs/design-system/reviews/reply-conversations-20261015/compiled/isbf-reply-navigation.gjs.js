import Component from "@glimmer/component";
import { fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import TopicNavigation from "discourse/components/topic-navigation";
import TopicTimeline from "discourse/components/topic-timeline";
import { popupAjaxError } from "discourse/lib/ajax-error";
import ReplyNavigation from "../lib/reply-navigation";
import { isConversationTopic } from "../lib/topic-card-scope";
import ISBFTopicReading from "./isbf-topic-reading";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i, n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFReplyNavigation extends Component {
  static {
    g(this.prototype, "appEvents", [service]);
  }
  #appEvents = (i(this, "appEvents"), void 0);
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
  static {
    g(this.prototype, "siteSettings", [service]);
  }
  #siteSettings = (i(this, "siteSettings"), void 0);
  navigation = this.enabled ? new ReplyNavigation(this.args.outletArgs.topic, this.appEvents) : null;
  trackGroups = modifier(element => {
    let frame;
    const view = element.closest(".nested-view");
    view?.classList.add("isbf-reply-conversations");
    const update = () => {
      const roots = [...(view?.querySelectorAll(".nested-post.--depth-0[data-root-index]") || [])];
      const current = roots.find(root => root.getBoundingClientRect().bottom > 60);
      const index = Number(current?.dataset.rootIndex);
      if (index) {
        this.navigation.notify(index);
      }
    };
    const schedule = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(update);
    };
    const observer = new MutationObserver(schedule);
    const roots = view?.querySelector(".nested-view__roots");
    if (roots) {
      observer.observe(roots, {
        childList: true,
        subtree: true
      });
    }
    window.addEventListener("scroll", schedule, {
      passive: true
    });
    schedule();
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      view?.classList.remove("isbf-reply-conversations");
      window.removeEventListener("scroll", schedule);
    };
  });
  willDestroy() {
    super.willDestroy(...arguments);
    this.navigation?.destroy();
  }
  get enabled() {
    return isConversationTopic(this.args.outletArgs.topic, this.router.currentURL, this.siteSettings);
  }
  get enteredIndex() {
    return (this.navigation?.currentIndex || 1) - 1;
  }
  get nestedController() {
    return getOwner(this).lookup("controller:nested");
  }
  jumpToIndex(index) {
    this.navigation.jumpToIndex(index).catch(popupAjaxError);
  }
  static {
    n(this.prototype, "jumpToIndex", [action]);
  }
  jumpToPost(number) {
    this.navigation.jumpToPostNumber(number);
  }
  static {
    n(this.prototype, "jumpToPost", [action]);
  }
  jumpTop(event) {
    event?.preventDefault();
    this.jumpToPost(1);
  }
  static {
    n(this.prototype, "jumpTop", [action]);
  }
  jumpEnd(event) {
    event?.preventDefault();
    this.jumpToIndex(this.navigation.total);
  }
  static {
    n(this.prototype, "jumpEnd", [action]);
  }
  sendTopicAction(name, ...args) {
    return getOwner(this).lookup("controller:topic").send(name, ...args);
  }
  static {
    n(this.prototype, "sendTopicAction", [action]);
  }
  jumpToDate(date) {
    return this.sendTopicAction("jumpToDate", date);
  }
  static {
    n(this.prototype, "jumpToDate", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.enabled}}
      <TopicNavigation
        class="topic-navigation"
        @jumpToDate={{this.jumpToDate}}
        @jumpToIndex={{this.jumpToPost}}
        @postCount={{@outletArgs.topic.highest_post_number}}
        @topic={{@outletArgs.topic}}
        {{this.trackGroups @outletArgs.topic.reply_navigation}}
        as |info|
      >
        <ISBFTopicReading
          @outletArgs={{hash
            topic=@outletArgs.topic
            navigation=this.navigation
            renderTimeline=true
            topicProgressExpanded=info.topicProgressExpanded
          }}
        />
        <TopicTimeline
          @convertToPrivateMessage={{fn
            this.sendTopicAction
            "convertToPrivateMessage"
          }}
          @convertToPublicTopic={{fn
            this.sendTopicAction
            "convertToPublicTopic"
          }}
          @deleteTopic={{fn this.sendTopicAction "deleteTopic"}}
          @enteredIndex={{this.enteredIndex}}
          @fullscreen={{info.topicProgressExpanded}}
          @jumpBottom={{this.jumpEnd}}
          @jumpEnd={{this.jumpEnd}}
          @jumpToIndex={{this.jumpToIndex}}
          @jumpTop={{this.jumpTop}}
          @model={{@outletArgs.topic}}
          @navigation={{this.navigation}}
          @recoverTopic={{fn this.sendTopicAction "recoverTopic"}}
          @replyToPost={{this.nestedController.replyToPost}}
          @resetBumpDate={{fn this.sendTopicAction "resetBumpDate"}}
          @showChangeTimestamp={{fn this.sendTopicAction "showChangeTimestamp"}}
          @showFeatureTopic={{fn this.sendTopicAction "showFeatureTopic"}}
          @showTopicSlowModeUpdate={{fn
            this.sendTopicAction
            "showTopicSlowModeUpdate"
          }}
          @showTopicTimerModal={{fn this.sendTopicAction "showTopicTimerModal"}}
          @toggleArchived={{fn this.sendTopicAction "toggleArchived"}}
          @toggleClosed={{fn this.sendTopicAction "toggleClosed"}}
          @toggleMultiSelect={{fn this.sendTopicAction "toggleMultiSelect"}}
          @toggleVisibility={{fn this.sendTopicAction "toggleVisibility"}}
        />
      </TopicNavigation>
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"enabled\"]],[[[1,\"  \"],[8,[32,0],[[24,0,\"topic-navigation\"],[4,[30,0,[\"trackGroups\"]],[[30,1,[\"topic\",\"reply_navigation\"]]],null]],[[\"@jumpToDate\",\"@jumpToIndex\",\"@postCount\",\"@topic\"],[[30,0,[\"jumpToDate\"]],[30,0,[\"jumpToPost\"]],[30,1,[\"topic\",\"highest_post_number\"]],[30,1,[\"topic\"]]]],[[\"default\"],[[[[1,\"\\n    \"],[8,[32,1],null,[[\"@outletArgs\"],[[28,[32,2],null,[[\"topic\",\"navigation\",\"renderTimeline\",\"topicProgressExpanded\"],[[30,1,[\"topic\"]],[30,0,[\"navigation\"]],true,[30,2,[\"topicProgressExpanded\"]]]]]]],null],[1,\"\\n    \"],[8,[32,3],null,[[\"@convertToPrivateMessage\",\"@convertToPublicTopic\",\"@deleteTopic\",\"@enteredIndex\",\"@fullscreen\",\"@jumpBottom\",\"@jumpEnd\",\"@jumpToIndex\",\"@jumpTop\",\"@model\",\"@navigation\",\"@recoverTopic\",\"@replyToPost\",\"@resetBumpDate\",\"@showChangeTimestamp\",\"@showFeatureTopic\",\"@showTopicSlowModeUpdate\",\"@showTopicTimerModal\",\"@toggleArchived\",\"@toggleClosed\",\"@toggleMultiSelect\",\"@toggleVisibility\"],[[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"convertToPrivateMessage\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"convertToPublicTopic\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"deleteTopic\"],null],[30,0,[\"enteredIndex\"]],[30,2,[\"topicProgressExpanded\"]],[30,0,[\"jumpEnd\"]],[30,0,[\"jumpEnd\"]],[30,0,[\"jumpToIndex\"]],[30,0,[\"jumpTop\"]],[30,1,[\"topic\"]],[30,0,[\"navigation\"]],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"recoverTopic\"],null],[30,0,[\"nestedController\",\"replyToPost\"]],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"resetBumpDate\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"showChangeTimestamp\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"showFeatureTopic\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"showTopicSlowModeUpdate\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"showTopicTimerModal\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"toggleArchived\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"toggleClosed\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"toggleMultiSelect\"],null],[28,[32,4],[[30,0,[\"sendTopicAction\"]],\"toggleVisibility\"],null]]],null],[1,\"\\n  \"]],[2]]]]],[1,\"\\n\"]],[]],null]],[\"@outletArgs\",\"info\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        TopicNavigation,
        ISBFTopicReading,
        hash,
        TopicTimeline,
        fn
      }),
      "isStrictMode": true
    }), this);
  }
}