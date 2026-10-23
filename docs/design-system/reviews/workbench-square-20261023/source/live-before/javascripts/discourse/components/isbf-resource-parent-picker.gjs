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
  async select(menu, id) {
    this.args.onChange(id);
    await menu.close();
  }

  <template>
    <DMenu
      @ariaLabel={{this.ariaLabel}}
      @constrainHeightToViewport={{true}}
      @contentClass="isbf-learning-grade-menu"
      @crossAxisShift={{false}}
      @disabled={{@disabled}}
      @icon="chevron-down"
      @inline={{@inline}}
      @label={{this.label}}
      @matchTriggerMinWidth={{true}}
      @modalForMobile={{false}}
      @placement="bottom-start"
      @strategy="fixed"
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
