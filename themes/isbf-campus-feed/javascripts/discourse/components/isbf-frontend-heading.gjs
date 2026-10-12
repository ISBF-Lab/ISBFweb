import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";
import {
  frontendConsistencyScope,
  normalizedRouteName,
} from "../lib/frontend-consistency-scope";

export default class ISBFFrontendHeading extends Component {
  @service("router") _router;

  get title() {
    const route = normalizedRouteName(this._router.currentRouteName);
    const scope = frontendConsistencyScope(route);
    if (scope?.id === "directory") {
      return i18n("directory.title");
    }
    if (scope?.id !== "preferences") {
      return null;
    }
    const child = route.split(".")[1];
    const overrides = {
      email: "user.email.title",
      "second-factor": "user.second_factor.title",
    };
    return i18n(
      overrides[child] ?? `user.preferences_nav.${child.replaceAll("-", "_")}`
    );
  }

  <template>
    {{#if this.title}}
      <h1 class="isbf-frontend__heading">{{this.title}}</h1>
    {{/if}}
  </template>
}
