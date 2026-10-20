import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { modifier } from "ember-modifier";
import DMenu from "discourse/float-kit/components/d-menu";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";

export default class ResumeShareListHeader extends Component {
  @tracked collapsed = true;

  observeSize = modifier((element) => {
    const title = element.querySelector("h1 > span");
    const actions = element.querySelector(".isbf-resume-share-list__actions");
    const observer = new ResizeObserver(() => {
      const gap = parseFloat(getComputedStyle(element).columnGap) || 0;
      this.collapsed =
        title.getBoundingClientRect().width +
          actions.getBoundingClientRect().width +
          gap >
        element.clientWidth;
    });
    [element, title, actions].forEach((target) => observer.observe(target));
    return () => observer.disconnect();
  });

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
    actions.push({
      label: "isbf_resume.sharing.upload",
      className: "isbf-resume-share-list__upload",
      href: getURL("/isbf/workbench/resume/shares/new"),
    });
    return actions;
  }

  @action
  async selectAction(close, item) {
    await close();
    item.action?.();
  }

  <template>
    <header
      class={{dConcatClass
        "isbf-resume-sharing-header isbf-resume-share-list__header"
        (if this.collapsed "has-overflow")
      }}
      ...attributes
      {{this.observeSize}}
    >
      <h1><span>{{@title}}</span></h1>
      <div
        aria-hidden={{if this.collapsed "true"}}
        class="isbf-resume-share-list__actions"
        inert={{this.collapsed}}
      >
        {{#each this.items as |item|}}
          <DButton
            class={{dConcatClass "btn-primary" item.className}}
            @action={{item.action}}
            @href={{item.href}}
            @label={{item.label}}
          />
        {{/each}}
      </div>
      {{#if this.collapsed}}
        <DMenu
          class="isbf-resume-share-list__more btn-transparent"
          @contentClass="isbf-resume-share-actions-menu"
          @icon="ellipsis"
          @identifier="isbf-resume-share-actions"
          @modalForMobile={{false}}
          @placement="bottom-end"
          @title="more"
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
    </header>
  </template>
}
