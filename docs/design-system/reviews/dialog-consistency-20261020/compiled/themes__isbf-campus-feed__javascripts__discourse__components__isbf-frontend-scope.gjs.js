import Component from "@glimmer/component";
import { service } from "@ember/service";
import bodyClass from "discourse/helpers/body-class";
import { frontendConsistencyScope } from "../lib/frontend-consistency-scope";
import { setComponentTemplate } from "@ember/component";
import { createTemplateFactory } from "@ember/template-factory";
import { g, i } from "/workspace/node_modules/.pnpm/decorator-transforms@2.4.0_@babel+core@7.29.7/node_modules/decorator-transforms/dist/runtime.js";
export default class ISBFFrontendScope extends Component {
  static {
    g(this.prototype, "_router", [service("router")]);
  }
  #_router = (i(this, "_router"), void 0);
  get bodyClasses() {
    const scope = frontendConsistencyScope(this._router.currentRouteName);
    if (!scope) {
      return null;
    }
    const classes = ["isbf-frontend", `is-frontend-${scope.id}`];
    if (scope.layout === "feature") {
      classes.push("has-frontend-feature");
    }
    classes.push(scope.userContent ? "has-frontend-user-content" : "has-frontend-page");
    return classes.join(" ");
  }
  static {
    setComponentTemplate(createTemplateFactory(
    /*
      {{bodyClass this.bodyClasses}}
    */
    {
      "id": null,
      "block": "[[[1,[28,[32,0],[[30,0,[\"bodyClasses\"]]],null]]],[],[]]",
      "moduleName": "(unknown template module)",
      "scope": () => ({
        bodyClass
      }),
      "isStrictMode": true
    }), this);
  }
}