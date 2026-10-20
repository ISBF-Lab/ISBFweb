import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { n } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFLearningGradePicker extends Component {
  get label() {
    return this.args.grades.find(grade => grade.id === this.args.value)?.label;
  }
  configureMenu(menu) {
    menu.options = {
      ...menu.options,
      constrainHeightToViewport: true,
      crossAxisShift: false,
      strategy: "fixed"
    };
  }
  static {
    n(this.prototype, "configureMenu", [action]);
  }
  async select(menu, id) {
    this.args.onChange(id);
    await menu.close();
  }
  static {
    n(this.prototype, "select", [action]);
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      <DMenu
      @ariaLabel={{i18n (themePrefix "isbf_v2.learning_grade")}}
      @contentClass="isbf-learning-grade-menu"
      @disabled={{@disabled}}
      @icon="chevron-down"
      @label={{this.label}}
      @matchTriggerMinWidth={{true}}
      @modalForMobile={{false}}
      @onRegisterApi={{this.configureMenu}}
      @placement="bottom-start"
      @triggerClass="btn-flat isbf-learning__grade"
      @visibilityOptimizer="none"
    >
      <:content as |menu|>
        <DDropdownMenu as |dropdown|>
          {{#each @grades as |grade|}}
            <dropdown.item>
              <DButton
                @action={{fn this.select menu grade.id}}
                @translatedLabel={{grade.label}}
              />
            </dropdown.item>
          {{/each}}
        </DDropdownMenu>
      </:content>
    </DMenu>
    */
    {
      "id": null,
      "block": "[[[8,[32,0],null,[[\"@ariaLabel\",\"@contentClass\",\"@disabled\",\"@icon\",\"@label\",\"@matchTriggerMinWidth\",\"@modalForMobile\",\"@onRegisterApi\",\"@placement\",\"@triggerClass\",\"@visibilityOptimizer\"],[[28,[32,1],[[28,[32,2],[\"isbf_v2.learning_grade\"],null]],null],\"isbf-learning-grade-menu\",[30,1],\"chevron-down\",[30,0,[\"label\"]],true,false,[30,0,[\"configureMenu\"]],\"bottom-start\",\"btn-flat isbf-learning__grade\",\"none\"]],[[\"content\"],[[[[1,\"\\n    \"],[8,[32,3],null,null,[[\"default\"],[[[[1,\"\\n\"],[42,[28,[31,1],[[28,[31,1],[[30,4]],null]],null],null,[[[1,\"        \"],[8,[30,3,[\"item\"]],null,null,[[\"default\"],[[[[1,\"\\n          \"],[8,[32,4],null,[[\"@action\",\"@translatedLabel\"],[[28,[32,5],[[30,0,[\"select\"]],[30,2],[30,5,[\"id\"]]],null],[30,5,[\"label\"]]]],null],[1,\"\\n        \"]],[]]]]],[1,\"\\n\"]],[5]],null],[1,\"    \"]],[3]]]]],[1,\"\\n  \"]],[2]]]]]],[\"@disabled\",\"menu\",\"dropdown\",\"@grades\",\"grade\"],[\"each\",\"-track-array\"]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        DMenu,
        i18n,
        themePrefix,
        DDropdownMenu,
        DButton,
        fn
      }),
      "isStrictMode": true
    }), this);
  }
}