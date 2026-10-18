import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";

export default class ISBFResourceParentPicker extends Component {
  get ariaLabel() {
    return this.args.label || i18n(themePrefix("isbf_v2.learning_grade"));
  }

  get label() {
    return (
      this.args.grades.find((grade) => grade.id === this.args.value)?.label ||
      this.args.label
    );
  }

  @action
  configureMenu(menu) {
    menu.options = {
      ...menu.options,
      constrainHeightToViewport: true,
      crossAxisShift: false,
      strategy: "fixed",
    };
  }

  @action
  async select(menu, id) {
    this.args.onChange(id);
    await menu.close();
  }

  <template>
    <DMenu
      @ariaLabel={{this.ariaLabel}}
      @contentClass="isbf-learning-grade-menu"
      @icon="chevron-down"
      @label={{this.label}}
      @matchTriggerMinWidth={{true}}
      @modalForMobile={{false}}
      @onRegisterApi={{this.configureMenu}}
      @placement="bottom-start"
      @title={{this.label}}
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
  </template>
}
