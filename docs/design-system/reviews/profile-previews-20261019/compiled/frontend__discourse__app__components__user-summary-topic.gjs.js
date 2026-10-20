/* eslint-disable ember/no-classic-components */import Component, { setComponentTemplate } from "@ember/component";
import { trustHTML } from "@ember/template";
import { tagName } from "@ember-decorators/component";
import PluginOutlet from "discourse/components/plugin-outlet";
import lazyHash from "discourse/helpers/lazy-hash";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dNumber from "discourse/ui-kit/helpers/d-number";
import { createTemplateFactory } from "@ember/template-factory";
import { c } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
const UserSummaryTopic = c(class UserSummaryTopic extends Component {
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <li ...attributes>
      <PluginOutlet
        @name="user-summary-topic-wrapper"
        @outletArgs={{lazyHash
          topic=@topic
          url=@url
          createdAt=@createdAt
          likes=@likes
        }}
      >
        <span class="topic-info">
          {{dFormatDate @createdAt format="tiny" noTitle="true"}}
          {{#if @likes}}
            &middot;
            {{dIcon "heart"}}&nbsp;<span class="like-count">{{dNumber
                @likes
              }}</span>
          {{/if}}
        </span>
        <br />
        <PluginOutlet
          @name="user-summary-topic-title"
          @outletArgs={{lazyHash topic=@topic url=@url postNumber=@postNumber}}
        >
          <a href={{@url}}>{{trustHTML @topic.fancyTitle}}</a>
        </PluginOutlet>
      </PluginOutlet>
    </li>
    */
    {
      "id": null,
      "block": "[[[11,\"li\"],[17,1],[12],[1,\"\\n  \"],[8,[32,0],null,[[\"@name\",\"@outletArgs\"],[\"user-summary-topic-wrapper\",[28,[32,1],null,[[\"topic\",\"url\",\"createdAt\",\"likes\"],[[30,2],[30,3],[30,4],[30,5]]]]]],[[\"default\"],[[[[1,\"\\n    \"],[10,1],[14,0,\"topic-info\"],[12],[1,\"\\n      \"],[1,[28,[32,2],[[30,4]],[[\"format\",\"noTitle\"],[\"tiny\",\"true\"]]]],[1,\"\\n\"],[41,[30,5],[[[1,\"        ·\\n        \"],[1,[28,[32,3],[\"heart\"],null]],[1,\" \"],[10,1],[14,0,\"like-count\"],[12],[1,[28,[32,4],[[30,5]],null]],[13],[1,\"\\n\"]],[]],null],[1,\"    \"],[13],[1,\"\\n    \"],[10,\"br\"],[12],[13],[1,\"\\n    \"],[8,[32,0],null,[[\"@name\",\"@outletArgs\"],[\"user-summary-topic-title\",[28,[32,1],null,[[\"topic\",\"url\",\"postNumber\"],[[30,2],[30,3],[30,6]]]]]],[[\"default\"],[[[[1,\"\\n      \"],[10,3],[15,6,[30,3]],[12],[1,[28,[32,5],[[30,2,[\"fancyTitle\"]]],null]],[13],[1,\"\\n    \"]],[]]]]],[1,\"\\n  \"]],[]]]]],[1,\"\\n\"],[13]],[\"&attrs\",\"@topic\",\"@url\",\"@createdAt\",\"@likes\",\"@postNumber\"],[\"if\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        PluginOutlet,
        lazyHash,
        dFormatDate,
        dIcon,
        dNumber,
        trustHTML
      }),
      "isStrictMode": true
    }), this);
  }
}, [tagName("")]);
export default UserSummaryTopic;