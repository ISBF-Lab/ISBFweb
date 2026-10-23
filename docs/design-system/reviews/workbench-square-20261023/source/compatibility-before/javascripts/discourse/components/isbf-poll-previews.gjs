import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { loadPostPolls } from "../lib/feed-post-loader";
import { buildPollPreviews, extractFeedPolls } from "../lib/poll-preview";

export default class ISBFPollPreviews extends Component {
  @service currentUser;

  @tracked data = null;
  @tracked failed = false;
  @tracked loadedIdentity = null;

  #request = 0;

  constructor() {
    super(...arguments);
    this.load();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#request += 1;
  }

  get viewerId() {
    return this.currentUser?.id || null;
  }

  get identity() {
    return `${this.viewerId || "guest"}:${this.args.postId}:${this.args.cooked}`;
  }

  get polls() {
    const current = this.loadedIdentity === this.identity;
    const data = current ? this.data : null;
    const descriptors = extractFeedPolls(
      data?.cooked ?? this.args.cooked
    ).polls;
    return buildPollPreviews(descriptors, data?.polls).map((poll) => ({
      ...poll,
      title: poll.title || i18n(themePrefix("isbf_v2.poll_button")),
      typeLabel: ["regular", "multiple", "number", "ranked_choice"].includes(
        poll.type
      )
        ? i18n(themePrefix(`isbf_v2.poll_type_${poll.type}`))
        : i18n(themePrefix("isbf_v2.poll_button")),
      votersLabel:
        poll.voters === null
          ? null
          : i18n(themePrefix("isbf_v2.poll_participants"), {
              count: poll.voters,
            }),
      remainingLabel: poll.remaining
        ? i18n(themePrefix("isbf_v2.poll_more_options"), {
            count: poll.remaining,
          })
        : null,
      options: poll.options.map((option) => ({
        ...option,
        hasPercentage: option.percentage !== null,
        percentageLabel:
          option.percentage === null
            ? null
            : i18n("number.percent", { count: option.percentage }),
        barStyle:
          option.percentage === null
            ? null
            : trustHTML(
                `width:${Math.max(0, Math.min(100, option.percentage))}%`
              ),
      })),
    }));
  }

  @action
  async load() {
    const request = ++this.#request;
    const identity = this.identity;
    this.loadedIdentity = null;
    this.data = null;
    this.failed = false;
    if (this.args.measureOnly) {
      return;
    }
    try {
      const data = await loadPostPolls(this.args.postId, this.viewerId, {
        refresh: true,
      });
      if (
        !this.isDestroying &&
        request === this.#request &&
        identity === this.identity
      ) {
        this.data = data;
        this.loadedIdentity = identity;
      }
    } catch {
      if (
        !this.isDestroying &&
        request === this.#request &&
        identity === this.identity
      ) {
        this.failed = true;
      }
    }
  }

  <template>
    <div
      class="isbf-poll-previews"
      {{didUpdate this.load @postId @cooked this.viewerId}}
    >
      {{#each this.polls key="name" as |poll|}}
        <section class="isbf-poll-preview">
          <h3 class="isbf-poll-preview__title">{{poll.title}}</h3>
          <div class="isbf-poll-preview__meta">
            <span>{{poll.typeLabel}}</span>
            {{#if poll.votersLabel}}<span>· {{poll.votersLabel}}</span>{{/if}}
            {{#if poll.closed}}<span>·
                {{i18n (themePrefix "isbf_v2.poll_closed")}}</span>{{/if}}
          </div>
          <ul class="isbf-poll-preview__options">
            {{#each poll.options key="id" as |option|}}
              <li class="isbf-poll-preview__option">
                <span class="isbf-poll-preview__label">{{option.label}}</span>
                {{#if option.hasPercentage}}
                  <span
                    class="isbf-poll-preview__percentage"
                  >{{option.percentageLabel}}</span>
                  <div aria-hidden="true" class="isbf-poll-preview__track">
                    <div
                      class="isbf-poll-preview__bar"
                      style={{option.barStyle}}
                    ></div>
                  </div>
                {{/if}}
              </li>
            {{/each}}
          </ul>
          {{#if this.failed}}<p class="isbf-poll-preview__meta">{{i18n
                (themePrefix "isbf_v2.poll_results_unavailable")
              }}</p>{{/if}}
          <div class="isbf-poll-preview__footer">
            {{#if poll.remainingLabel}}<span
                class="isbf-poll-preview__more"
              >{{poll.remainingLabel}}</span>{{/if}}
            <a class="isbf-poll-preview__link" href={{@topicUrl}}>{{i18n
                (themePrefix "isbf_v2.poll_view")
              }}</a>
          </div>
        </section>
      {{/each}}
    </div>
  </template>
}
