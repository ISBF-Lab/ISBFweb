import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class ISBFWorkbenchTopicPage extends Component {
  @service isbfBackNavigation;

  get labels() {
    const prefix = this.args.kind;
    return Object.fromEntries(
      ["back", "empty", "error", "login", "publish", "unavailable"].map(
        (key) => [key, i18n(themePrefix(`isbf_v2.${prefix}_${key}`))]
      )
    );
  }

  get title() {
    return i18n(themePrefix(`isbf_v2.workbench_${this.args.kind}`));
  }

  get backHref() {
    return this.isbfBackNavigation.href("/isbf/workbench");
  }

  @action
  goBack(event) {
    this.isbfBackNavigation.back(event);
  }

  <template>
    <main
      aria-busy={{@loading}}
      class="isbf-workbench-topic-page"
      ...attributes
    >
      <header class="isbf-marketplace__header">
        <a
          aria-label={{i18n "back_button"}}
          href={{this.backHref}}
          {{on "click" this.goBack}}
        >{{dIcon "arrow-left"}}</a>
        <h1>{{this.title}}</h1>
      </header>
      {{#if @config}}
        {{#if @currentUser}}
          {{yield}}
          {{#if @loading}}
            <p class="isbf-marketplace__notice" role="status">{{i18n
                (themePrefix "isbf_v2.learning_loading")
              }}</p>
          {{else if @error}}
            <p
              class="isbf-marketplace__notice"
              role="alert"
            >{{this.labels.error}}</p>
            <DButton
              @action={{@onRetry}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.explore_retry")}}
            />
          {{else if @canLoadMore}}
            <DButton
              @action={{@onLoadMore}}
              @translatedLabel={{i18n (themePrefix "isbf_v2.load_more")}}
            />
          {{else}}
            {{#unless @hasTopics}}
              <p class="isbf-marketplace__notice">{{this.labels.empty}}</p>
            {{/unless}}
          {{/if}}
          {{#if @canCreate}}
            <DButton
              class="btn-primary isbf-marketplace__create"
              @action={{@onCreate}}
              @icon="plus"
              @translatedLabel={{this.labels.publish}}
            />
          {{/if}}
        {{else}}
          <div class="isbf-marketplace__notice">
            <p>{{this.labels.login}}</p>
            <DButton @action={{@onLogin}} @label="log_in" />
          </div>
        {{/if}}
      {{else}}
        <p class="isbf-marketplace__notice">{{this.labels.unavailable}}</p>
      {{/if}}
    </main>
  </template>
}
