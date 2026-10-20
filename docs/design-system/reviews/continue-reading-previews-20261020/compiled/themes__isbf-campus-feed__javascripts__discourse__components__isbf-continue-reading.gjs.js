import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import UserTip from "discourse/components/user-tip";
import EmbedMode from "discourse/lib/embed-mode";
import { eq, gt } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import ISBFContinueReadingFooter from "./isbf-continue-reading-footer";
import ISBFContinueReadingItem from "./isbf-continue-reading-item";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFContinueReading extends Component {
  static {
    g(this.prototype, "moreTopicsTabs", [service]);
  }
  #moreTopicsTabs = (i(this, "moreTopicsTabs"), void 0);
  static {
    g(this.prototype, "router", [service]);
  }
  #router = (i(this, "router"), void 0);
  get topic() {
    return this.args.outletArgs.topic;
  }
  get listContext() {
    return this.moreTopicsTabs.selectedTab?.id === "suggested-topics" ? "suggested" : "related";
  }
  get shouldRender() {
    return !EmbedMode.enabled && /^\/t\//.test(this.router.currentURL ?? "") && this.topic.archetype === "regular" && this.topics?.length > 0;
  }
  get sourceTitle() {
    return this.listContext === "suggested" ? i18n(themePrefix("isbf_v2.continue_reading.suggested")) : i18n(themePrefix("isbf_v2.continue_reading.related"));
  }
  get topics() {
    switch (this.moreTopicsTabs.selectedTab?.id) {
      case "suggested-topics":
        return this.topic.suggestedTopics;
      case "related-topics":
        return this.topic.relatedTopics;
      default:
        return null;
    }
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{#if this.shouldRender}}
      <section
        aria-labelledby="isbf-continue-reading-title"
        class="isbf-continue-reading"
        data-source={{this.listContext}}
        id={{this.moreTopicsTabs.selectedTab.id}}
        ...attributes
      >
        {{#if (eq this.listContext "suggested")}}
          <UserTip
            @contentText={{i18n "user_tips.suggested_topics.content"}}
            @id="suggested_topics"
            @placement="top-start"
            @priority={{700}}
            @titleText={{i18n "user_tips.suggested_topics.title"}}
          />
        {{/if}}
    
        <header class="isbf-continue-reading__header">
          <h3
            class="isbf-continue-reading__heading"
            id="isbf-continue-reading-title"
          >
            {{i18n (themePrefix "isbf_v2.continue_reading.title")}}
          </h3>
          <span
            class="isbf-continue-reading__source"
          >{{this.sourceTitle}}</span>
        </header>
    
        {{#if (gt this.moreTopicsTabs.tabs.length 1)}}
          <nav
            aria-label={{i18n (themePrefix "isbf_v2.continue_reading.sources")}}
            class="isbf-continue-reading__tabs"
          >
            {{#each this.moreTopicsTabs.tabs as |tab|}}
              <DButton
                aria-pressed={{this.moreTopicsTabs.isActiveTab tab}}
                class={{dConcatClass
                  "isbf-continue-reading__tab"
                  (if (this.moreTopicsTabs.isActiveTab tab) "is-active")
                }}
                @action={{fn this.moreTopicsTabs.selectTab tab}}
                @translatedLabel={{tab.name}}
              />
            {{/each}}
          </nav>
        {{/if}}
    
        <ul class="isbf-continue-reading__list" role="list">
          {{#each this.topics key="id" as |topic index|}}
            <ISBFContinueReadingItem
              @index={{index}}
              @listContext={{this.listContext}}
              @topic={{topic}}
            />
          {{/each}}
        </ul>
    
        {{#if this.topic.suggestedTopics.length}}
          <ISBFContinueReadingFooter @topic={{this.topic}} />
        {{/if}}
      </section>
    {{else}}
      {{yield}}
    {{/if}}
    */
    {
      "id": null,
      "block": "[[[41,[30,0,[\"shouldRender\"]],[[[1,\"  \"],[11,\"section\"],[24,\"aria-labelledby\",\"isbf-continue-reading-title\"],[24,0,\"isbf-continue-reading\"],[16,\"data-source\",[30,0,[\"listContext\"]]],[16,1,[30,0,[\"moreTopicsTabs\",\"selectedTab\",\"id\"]]],[17,1],[12],[1,\"\\n\"],[41,[28,[32,0],[[30,0,[\"listContext\"]],\"suggested\"],null],[[[1,\"      \"],[8,[32,1],null,[[\"@contentText\",\"@id\",\"@placement\",\"@priority\",\"@titleText\"],[[28,[32,2],[\"user_tips.suggested_topics.content\"],null],\"suggested_topics\",\"top-start\",700,[28,[32,2],[\"user_tips.suggested_topics.title\"],null]]],null],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,\"header\"],[14,0,\"isbf-continue-reading__header\"],[12],[1,\"\\n      \"],[10,\"h3\"],[14,0,\"isbf-continue-reading__heading\"],[14,1,\"isbf-continue-reading-title\"],[12],[1,\"\\n        \"],[1,[28,[32,2],[[28,[32,3],[\"isbf_v2.continue_reading.title\"],null]],null]],[1,\"\\n      \"],[13],[1,\"\\n      \"],[10,1],[14,0,\"isbf-continue-reading__source\"],[12],[1,[30,0,[\"sourceTitle\"]]],[13],[1,\"\\n    \"],[13],[1,\"\\n\\n\"],[41,[28,[32,4],[[30,0,[\"moreTopicsTabs\",\"tabs\",\"length\"]],1],null],[[[1,\"      \"],[10,\"nav\"],[15,\"aria-label\",[28,[32,2],[[28,[32,3],[\"isbf_v2.continue_reading.sources\"],null]],null]],[14,0,\"isbf-continue-reading__tabs\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"moreTopicsTabs\",\"tabs\"]]],null]],null],null,[[[1,\"          \"],[8,[32,5],[[16,\"aria-pressed\",[28,[30,0,[\"moreTopicsTabs\",\"isActiveTab\"]],[[30,2]],null]],[16,0,[28,[32,6],[\"isbf-continue-reading__tab\",[52,[28,[30,0,[\"moreTopicsTabs\",\"isActiveTab\"]],[[30,2]],null],\"is-active\"]],null]]],[[\"@action\",\"@translatedLabel\"],[[28,[32,7],[[30,0,[\"moreTopicsTabs\",\"selectTab\"]],[30,2]],null],[30,2,[\"name\"]]]],null],[1,\"\\n\"]],[2]],null],[1,\"      \"],[13],[1,\"\\n\"]],[]],null],[1,\"\\n    \"],[10,\"ul\"],[14,0,\"isbf-continue-reading__list\"],[14,\"role\",\"list\"],[12],[1,\"\\n\"],[42,[28,[31,2],[[28,[31,2],[[30,0,[\"topics\"]]],null]],null],\"id\",[[[1,\"        \"],[8,[32,8],null,[[\"@index\",\"@listContext\",\"@topic\"],[[30,4],[30,0,[\"listContext\"]],[30,3]]],null],[1,\"\\n\"]],[3,4]],null],[1,\"    \"],[13],[1,\"\\n\\n\"],[41,[30,0,[\"topic\",\"suggestedTopics\",\"length\"]],[[[1,\"      \"],[8,[32,9],null,[[\"@topic\"],[[30,0,[\"topic\"]]]],null],[1,\"\\n\"]],[]],null],[1,\"  \"],[13],[1,\"\\n\"]],[]],[[[1,\"  \"],[18,5,null],[1,\"\\n\"]],[]]]],[\"&attrs\",\"tab\",\"topic\",\"index\",\"&default\"],[\"if\",\"each\",\"-track-array\",\"yield\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        eq,
        UserTip,
        i18n,
        themePrefix,
        gt,
        DButton,
        dConcatClass,
        fn,
        ISBFContinueReadingItem,
        ISBFContinueReadingFooter
      }),
      "isStrictMode": true
    }), this);
  }
}