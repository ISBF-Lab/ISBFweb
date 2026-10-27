/* eslint-disable ember/no-classic-components, ember/require-tagless-components */
import Component from "@ember/component";
import { computed } from "@ember/object";
import { next } from "@ember/runloop";
import { classNameBindings, classNames } from "@ember-decorators/component";
import { bind } from "discourse/lib/decorators";
import MenuHighlight from "discourse/ui-kit/-internals/menu-highlight";

@classNames("select-kit-body", "d-menu-surface", "d-menu-highlight")
@classNameBindings("emptyBody:empty-body")
export default class SelectKitBody extends Component {
  #highlight;

  @computed("selectKit.{filter,hasNoContent}")
  get emptyBody() {
    return false;
  }

  didInsertElement() {
    super.didInsertElement(...arguments);

    this.#highlight = new MenuHighlight(this.element, {
      itemSelector: ".select-kit-row",
      activeSelector: ".is-highlighted",
    });

    document.addEventListener("click", this.handleClick, true);
    this.selectKit
      .mainElement()
      .addEventListener("keydown", this._handleKeydown, true);
  }

  willDestroyElement() {
    super.willDestroyElement(...arguments);
    this.#highlight?.disconnect();
    document.removeEventListener("click", this.handleClick, true);
    this.selectKit
      .mainElement()
      ?.removeEventListener("keydown", this._handleKeydown, true);
  }

  @bind
  handleClick(event) {
    if (!this.selectKit.isExpanded || !this.selectKit.mainElement()) {
      return;
    }

    if (this.selectKit.mainElement().contains(event.target)) {
      return;
    }

    this.selectKit.close(event);
  }

  @bind
  _handleKeydown(event) {
    if (!this.selectKit.isExpanded || event.key !== "Tab") {
      return;
    }

    next(() => {
      if (
        this.isDestroying ||
        this.selectKit.mainElement()?.contains(document.activeElement)
      ) {
        return;
      }

      this.selectKit.close(event);
    });
  }

  <template>
    {{#if this.selectKit.isExpanded}}
      {{yield}}
    {{/if}}
  </template>
}
