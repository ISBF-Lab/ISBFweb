import Component from "@glimmer/component";
import { service } from "@ember/service";
import bodyClass from "discourse/helpers/body-class";
import { frontendConsistencyScope } from "../lib/frontend-consistency-scope";

export default class ISBFFrontendScope extends Component {
  @service("router") _router;

  get bodyClasses() {
    const scope = frontendConsistencyScope(this._router.currentRouteName);
    if (!scope) {
      return null;
    }
    const classes = ["isbf-frontend", `is-frontend-${scope.id}`];
    if (scope.layout === "feature") {
      classes.push("has-frontend-feature");
    }
    classes.push(
      scope.userContent ? "has-frontend-user-content" : "has-frontend-page"
    );
    return classes.join(" ");
  }

  <template>{{bodyClass this.bodyClasses}}</template>
}
