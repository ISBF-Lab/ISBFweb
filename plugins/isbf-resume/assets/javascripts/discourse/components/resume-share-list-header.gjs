import Component from "@glimmer/component";
import { array, fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import DMenu from "discourse/float-kit/components/d-menu";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";

export default class ResumeShareListHeader extends Component {
  get items() {
    const actions = [];
    if (this.args.canManageCollection) {
      actions.push({
        label: "isbf_resume.sharing.edit_collection",
        action: this.args.onEditCollection,
      });
    }
    if (this.args.published) {
      actions.push({
        label: "isbf_resume.sharing.mine",
        className: "isbf-resume-share-list__mine",
        href: getURL("/isbf/workbench/resume/shares/mine"),
      });
    }
    return actions;
  }

  get uploadHref() {
    return getURL("/isbf/workbench/resume/shares/new");
  }

  @action
  async selectAction(close, item) {
    await close();
    item.action?.();
  }

  <template>
    <header
      class="isbf-resume-sharing-header isbf-resume-share-list__header"
      ...attributes
    >
      <h1><span>{{@title}}</span></h1>
      <div class="isbf-resume-share-list__actions">
        <DButton
          class="btn-primary isbf-resume-share-list__upload"
          @href={{this.uploadHref}}
          @label="isbf_resume.sharing.apply_share"
        />
        {{#if this.items.length}}
          <DMenu
            class="isbf-resume-share-list__more btn-transparent"
            @contentClass="isbf-resume-share-actions-menu"
            @icon="ellipsis"
            @identifier="isbf-resume-share-actions"
            @interactive={{true}}
            @modalForMobile={{false}}
            @placement="bottom-end"
            @title={{i18n "more"}}
            @triggers={{hash
              desktop=(array "hover" "click")
              mobile=(array "click")
            }}
            @untriggers={{hash
              desktop=(array "hover" "click")
              mobile=(array "click")
            }}
            as |menu|
          >
            <DDropdownMenu as |dropdown|>
              {{#each this.items as |item|}}
                <dropdown.item>
                  {{#if item.href}}
                    <a
                      class="isbf-resume-share-actions-menu__item"
                      href={{item.href}}
                      {{on "click" (fn this.selectAction menu.close item)}}
                    >{{i18n item.label}}</a>
                  {{else}}
                    <DButton
                      class="isbf-resume-share-actions-menu__item"
                      @action={{fn this.selectAction menu.close item}}
                      @label={{item.label}}
                    />
                  {{/if}}
                </dropdown.item>
              {{/each}}
            </DDropdownMenu>
          </DMenu>
        {{/if}}
      </div>
    </header>
  </template>
}
