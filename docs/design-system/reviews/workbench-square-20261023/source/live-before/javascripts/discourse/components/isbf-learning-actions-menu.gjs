import Component from "@glimmer/component";
import { array, fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import { themePrefix } from "virtual:theme";
import DMenu from "discourse/float-kit/components/d-menu";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";

export default class ISBFLearningActionsMenu extends Component {
  @action
  async performAction(menu, callback, ...args) {
    await menu.close();
    return callback(...args);
  }

  <template>
    <DMenu
      @ariaLabel={{i18n "more"}}
      @contentClass="isbf-learning-actions-menu"
      @icon="ellipsis"
      @identifier="isbf-learning-header-actions"
      @interactive={{true}}
      @modalForMobile={{false}}
      @placement="bottom-end"
      @title={{i18n "more"}}
      @triggerClass="btn-transparent isbf-learning__actions-trigger"
      @triggers={{hash desktop=(array "hover" "click") mobile=(array "click")}}
      @untriggers={{hash
        desktop=(array "hover" "click")
        mobile=(array "click")
      }}
    >
      <:content as |menu|>
        <DDropdownMenu as |dropdown|>
          {{#if @page.canManageResources}}
            {{#unless @page.myContributions}}
              {{#unless @page.searching}}
                {{#if @page.selectedCourse}}
                  <dropdown.item>
                    <DButton
                      class="isbf-learning-actions-menu__item isbf-learning__edit-course"
                      @action={{fn
                        this.performAction
                        menu
                        @page.editCourse
                        @page.selectedCourse
                      }}
                      @translatedLabel={{i18n
                        (themePrefix
                          (if
                            @page.isLibrary
                            "isbf_v2.library_edit_group"
                            "isbf_v2.learning_edit_course"
                          )
                        )
                      }}
                    />
                  </dropdown.item>
                {{/if}}
              {{/unless}}
            {{/unless}}
          {{/if}}
          {{#if @page.canManageCollectionForm}}
            <dropdown.item>
              <DButton
                class="isbf-learning-actions-menu__item isbf-learning__collection-settings"
                @action={{fn this.performAction menu @page.editCollectionForm}}
                @translatedLabel={{i18n
                  (themePrefix "isbf_v2.learning_collection_settings")
                }}
              />
            </dropdown.item>
          {{/if}}
          <dropdown.item>
            <DButton
              class="isbf-learning-actions-menu__item isbf-learning__contributions"
              @action={{fn this.performAction menu @page.toggleContributions}}
              @ariaPressed={{@page.myContributions}}
              @translatedLabel={{i18n
                (themePrefix
                  (if
                    @page.myContributions
                    "isbf_v2.learning_all_resources"
                    "isbf_v2.learning_my_contributions"
                  )
                )
              }}
            />
          </dropdown.item>
        </DDropdownMenu>
      </:content>
    </DMenu>
  </template>
}
