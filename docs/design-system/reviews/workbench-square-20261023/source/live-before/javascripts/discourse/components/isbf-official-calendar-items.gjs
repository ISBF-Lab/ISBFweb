import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import {
  OFFICIAL_CALENDAR_FIELD,
  officialTimeLabel,
} from "../lib/official-calendar";
import { isOfficialCalendarPost } from "../lib/official-topic-scope";
import ISBFOfficialActivitySummary from "./isbf-official-activity-summary";

export default class ISBFOfficialCalendarItems extends Component {
  @service appEvents;
  @service currentUser;
  @service router;
  @service site;

  @tracked error = false;
  #requestGeneration = 0;
  @tracked _busyId = null;
  @tracked _entryIds = {};
  @tracked _refreshedItems = null;
  @tracked _refreshedCampuses = null;

  @tracked _refreshedPostId = null;

  constructor() {
    super(...arguments);
    this.appEvents.on("isbf:calendar-entry-changed", this.onEntryChanged);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.#requestGeneration++;
    this.appEvents.off("isbf:calendar-entry-changed", this.onEntryChanged);
  }

  get post() {
    return this.args.outletArgs?.post;
  }

  get officialLayout() {
    return isOfficialCalendarPost(
      this.post,
      this.site,
      this.router.currentURL,
      this.args.outletArgs?.state?.nestedReplyView
    );
  }

  get topicTitle() {
    return this.args.topicTitle ?? this.post?.topic?.title;
  }

  get campusIds() {
    return (
      (this._refreshedPostId === this.post?.id
        ? this._refreshedCampuses
        : null) ??
      this.args.campusIds ??
      this.post?.isbf_official_campuses ??
      this.post?.topic?.isbf_official_campuses
    );
  }

  get items() {
    const source =
      (this._refreshedPostId === this.post?.id ? this._refreshedItems : null) ??
      this.args.items ??
      this.post?.[OFFICIAL_CALENDAR_FIELD] ??
      [];
    const multiple = source.filter((item) => !item.cancelled).length > 1;
    return source.map((item) => {
      const added = Boolean(
        Object.hasOwn(this._entryIds, item.id)
          ? this._entryIds[item.id]
          : item.personal_entry_id
      );
      return {
        ...item,
        timeLabel: officialTimeLabel(item),
        added,
        busy: this._busyId === item.id,
        addDisabled: Boolean(this._busyId || added || item.cancelled),
        addLabel: themePrefix(
          added
            ? "isbf_v2.schedule_added"
            : !multiple
              ? "isbf_v2.schedule_add"
              : item.schedule_kind === "deadline"
                ? "isbf_v2.schedule_add_deadline"
                : "isbf_v2.schedule_add_event"
        ),
      };
    });
  }

  @action
  onEntryChanged({ source_item_id, id, removed } = {}) {
    if (!this.isDestroying && source_item_id) {
      this._entryIds = {
        ...this._entryIds,
        [source_item_id]: removed ? null : id,
      };
    }
  }

  @action
  async add(item) {
    if (this.args.readOnly || this.isDestroying) {
      return;
    }
    if (!this.currentUser) {
      this.router.transitionTo("login");
      return;
    }
    if (this._busyId || item.added || item.cancelled) {
      return;
    }
    const request = ++this.#requestGeneration;
    const postId = this.post?.id;
    this._busyId = item.id;
    this.error = false;
    try {
      const { entry } = await ajax(
        `/isbf/api/official-items/${item.id}/add.json`,
        {
          type: "POST",
          data: { revision: item.revision },
        }
      );
      if (this.#isCurrent(request, postId)) {
        this.appEvents.trigger("isbf:calendar-entry-changed", entry);
      }
    } catch (error) {
      if (this.#isCurrent(request, postId)) {
        this.error = true;
        if (error.jqXHR?.status === 409 && postId) {
          try {
            const post = await ajax(`/posts/${postId}.json`);
            if (this.#isCurrent(request, postId)) {
              this._refreshedPostId = postId;
              this._refreshedItems = post[OFFICIAL_CALENDAR_FIELD] ?? [];
              this._refreshedCampuses = post.isbf_official_campuses ?? null;
            }
          } catch {
            if (this.#isCurrent(request, postId)) {
              this.error = true;
            }
          }
        }
      }
    } finally {
      if (!this.isDestroying && request === this.#requestGeneration) {
        this._busyId = null;
      }
    }
  }

  #isCurrent(request, postId) {
    return (
      !this.isDestroying &&
      request === this.#requestGeneration &&
      this.post?.id === postId
    );
  }

  <template>
    {{#if this.items.length}}
      {{#if this.officialLayout}}
        <ISBFOfficialActivitySummary
          @campusIds={{this.campusIds}}
          @items={{this.items}}
          @topicTitle={{this.topicTitle}}
          as |item|
        >
          {{#unless @readOnly}}
            <DButton
              class="btn-primary"
              @action={{fn this.add item}}
              @disabled={{item.addDisabled}}
              @icon={{if item.added "check" "calendar-days"}}
              @isLoading={{item.busy}}
              @label={{item.addLabel}}
            />
          {{/unless}}
        </ISBFOfficialActivitySummary>
      {{else}}
        <section
          aria-label={{i18n (themePrefix "isbf_v2.schedule_editor_title")}}
          class="isbf-official-calendar-items"
        >
          {{#each this.items key="id" as |item|}}
            <div
              class="isbf-official-calendar-items__item"
              data-schedule-id={{item.id}}
            >
              <div class="isbf-official-calendar-items__information">
                <strong>{{item.title}}</strong><span>{{item.timeLabel}}</span>
              </div>
              {{#unless @readOnly}}
                <DButton
                  @action={{fn this.add item}}
                  @disabled={{item.addDisabled}}
                  @icon={{if item.added "check" "calendar-days"}}
                  @isLoading={{item.busy}}
                  @label={{item.addLabel}}
                />
              {{/unless}}
            </div>
          {{/each}}
        </section>
      {{/if}}
      {{#if this.error}}
        <p class="isbf-official-calendar-items__error" role="alert">
          {{i18n (themePrefix "isbf_v2.schedule_add_error")}}
        </p>
      {{/if}}
    {{/if}}
  </template>
}
