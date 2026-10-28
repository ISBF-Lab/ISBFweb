import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import DiscoveryTopicsList from "discourse/components/discovery-topics-list";
import hideApplicationFooter from "discourse/helpers/hide-application-footer";
import periodTitle from "discourse/helpers/period-title";
import { eq, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import DLoadMore from "discourse/ui-kit/d-load-more";
import DSelect from "discourse/ui-kit/d-select";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import ISBFTopTopicsItem from "./isbf-top-topics-item";

export default class ISBFTopTopics extends Component {
  @service site;

  @tracked _failedModel;

  get loadFailed() {
    return this._failedModel === this.args.model;
  }

  @action
  async loadMore() {
    const model = this.args.model;
    if (this.loadFailed || model.loadingMore || !model.canLoadMore) {
      return;
    }

    try {
      await model.loadMore();
    } catch {
      model.set("loadingMore", false);
      if (!this.isDestroying && this.args.model === model) {
        this._failedModel = model;
      }
    }
  }

  @action
  retry() {
    this._failedModel = undefined;
    return this.loadMore();
  }

  <template>
    {{#if @model.canLoadMore}}{{hideApplicationFooter}}{{/if}}
    <section
      aria-label={{i18n (themePrefix "isbf_v2.top_topics.title")}}
      class="isbf-top-topics"
      ...attributes
    >
      <div class="isbf-top-topics__filters">
        <div class="isbf-top-topics__period">
          <span class="isbf-top-topics__label">{{i18n
              (themePrefix "isbf_v2.top_topics.period")
            }}</span>
          <div class="isbf-top-topics__range">
            {{#if (eq @model.for_period "all")}}
              {{periodTitle "all"}}
            {{else}}
              {{periodTitle @model.for_period showDateRange=true fullDay=false}}
            {{/if}}
          </div>
        </div>
        <DSelect
          aria-label={{i18n (themePrefix "isbf_v2.top_topics.period")}}
          class="isbf-top-topics__select"
          @includeNone={{false}}
          @onChange={{@onPeriodChange}}
          @value={{@model.for_period}}
          as |select|
        >
          {{#each this.site.periods as |period|}}
            <select.Option @value={{period}}>{{periodTitle
                period
              }}</select.Option>
          {{/each}}
        </DSelect>
      </div>

      <DiscoveryTopicsList @incomingCount={{0}} @model={{@model}}>
        {{#if @model.topics.length}}
          <table class="isbf-top-topics__list topic-list">
            <caption class="sr-only">{{i18n
                (themePrefix "isbf_v2.top_topics.title")
              }}</caption>
            <tbody>
              {{#each @model.topics key="id" as |topic index|}}
                <ISBFTopTopicsItem
                  @focusLastVisitedTopic={{true}}
                  @index={{index}}
                  @listContext="discovery"
                  @topic={{topic}}
                />
              {{/each}}
            </tbody>
          </table>
          {{#unless this.loadFailed}}
            <DLoadMore
              @action={{this.loadMore}}
              @enabled={{@model.canLoadMore}}
              @isLoading={{@model.loadingMore}}
            />
          {{/unless}}
        {{else}}
          <div class="isbf-top-topics__empty" role="status">
            {{dIcon "chart-line"}}
            <p>{{i18n (themePrefix "isbf_v2.top_topics.empty")}}</p>
            <span>{{i18n (themePrefix "isbf_v2.top_topics.empty_hint")}}</span>
          </div>
        {{/if}}
      </DiscoveryTopicsList>

      {{#if (or @model.loadingMore this.loadFailed)}}
        <div aria-live="polite" class="isbf-top-topics__footer">
          <DConditionalLoadingSpinner @condition={{@model.loadingMore}} />
          {{#if this.loadFailed}}
            <p>{{i18n (themePrefix "isbf_v2.top_topics.load_error")}}</p>
            <DButton
              class="btn-flat isbf-top-topics__retry"
              @action={{this.retry}}
              @label="retry"
            />
          {{/if}}
        </div>
      {{/if}}
    </section>
  </template>
}
