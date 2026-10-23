import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { bind } from "discourse/lib/decorators";
import getURL from "discourse/lib/get-url";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import BackNavigationHistory from "../lib/back-navigation-history";

export default class ISBFBackNavigation extends Service {
  @service router;
  @service sessionStore;

  @tracked previousURL = null;

  #history;
  #onPopState = () => {
    this.#history.traverse();
    this.previousURL = this.#history.previousURL;
  };

  constructor() {
    super(...arguments);
    this.#history = new BackNavigationHistory(this.sessionStore);
    this.previousURL = this.#history.previousURL;
    this.router.on("routeWillChange", this.captureBrowserEntry);
    this.router.on("routeDidChange", this.recordTransition);
    window.addEventListener("popstate", this.#onPopState, true);
    // Topic scrolling replaces the history UUID without emitting route events.
    window.addEventListener("pagehide", this.captureBrowserEntry);
  }

  willDestroy() {
    this.router.off("routeWillChange", this.captureBrowserEntry);
    this.router.off("routeDidChange", this.recordTransition);
    window.removeEventListener("popstate", this.#onPopState, true);
    window.removeEventListener("pagehide", this.captureBrowserEntry);
    super.willDestroy(...arguments);
  }

  back(event) {
    if (wantsNewWindow(event) || event.altKey) {
      return;
    }
    this.captureBrowserEntry();
    if (this.previousURL) {
      event.preventDefault();
      window.history.back();
    }
  }

  href(fallback) {
    return this.previousURL ?? getURL(fallback);
  }

  @bind
  captureBrowserEntry() {
    this.#history.capture();
    this.previousURL = this.#history.previousURL;
  }

  @bind
  recordTransition(transition) {
    if (transition.isAborted) {
      return;
    }

    transition.then(
      () => {
        if (!this.isDestroying) {
          this.#history.commit(
            !transition.from || transition.urlMethod === "replace"
          );
          this.previousURL = this.#history.previousURL;
        }
      },
      () => {}
    );
  }
}
