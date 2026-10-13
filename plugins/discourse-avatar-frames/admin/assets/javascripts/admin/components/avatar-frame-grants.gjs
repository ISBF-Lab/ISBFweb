import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array, concat, fn, hash } from "@ember/helper";
import { action } from "@ember/object";
import { cancel, later } from "@ember/runloop";
import { service } from "@ember/service";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import BackButton from "discourse/components/back-button";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import UserChooser from "discourse/select-kit/components/user-chooser";
import { gt, not } from "discourse/truth-helpers";
import DBreadcrumbsItem from "discourse/ui-kit/d-breadcrumbs-item";
import DButton from "discourse/ui-kit/d-button";
import DPickFilesButton from "discourse/ui-kit/d-pick-files-button";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";
import { frameName } from "discourse/plugins/discourse-avatar-frames/discourse/lib/avatar-frames";

export default class AvatarFrameGrants extends Component {
  @service dialog;

  @tracked page;
  @tracked importList;
  @tracked notice;
  @tracked offset = 0;
  @tracked search = "";
  @tracked importing = false;

  #poll;

  constructor() {
    super(...arguments);
    if (
      this.imports.some((item) =>
        ["queued", "processing"].includes(item.status)
      )
    ) {
      this.#schedulePoll();
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    cancel(this.#poll);
  }

  get frame() {
    return this.args.data.frame;
  }

  get baseUrl() {
    return `/avatar-frames/admin/frames/${this.frame.id}`;
  }

  get grants() {
    return this.page?.grants || this.args.data.grants;
  }

  get total() {
    return this.page?.total ?? this.args.data.total;
  }

  get hasNext() {
    return this.offset + this.grants.length < this.total;
  }

  get imports() {
    return this.importList || this.args.data.imports;
  }

  @action
  async grant({ user }) {
    try {
      const result = await ajax(`${this.baseUrl}/grants`, {
        type: "POST",
        data: { username: user[0] },
      });
      this.notice = i18n(
        result.newly_granted
          ? "avatar_frames.admin.awarded"
          : "avatar_frames.admin.already_awarded"
      );
      await this.#loadGrants();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  pickCsv(set, files) {
    set(files[0]);
  }

  @action
  async importCsv({ file }) {
    this.importing = true;
    try {
      const data = new FormData();
      data.append("file", file);
      const result = await ajax(`${this.baseUrl}/imports`, {
        type: "POST",
        processData: false,
        contentType: false,
        data,
      });
      this.importList = [result.import, ...this.imports].slice(0, 20);
      this.#schedulePoll();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.importing = false;
    }
  }

  @action
  async filter({ username }) {
    this.search = username || "";
    this.offset = 0;
    try {
      await this.#loadGrants();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async turnPage(direction) {
    this.offset = Math.max(0, this.offset + direction * 50);
    try {
      await this.#loadGrants();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  revoke(grant) {
    this.dialog.deleteConfirm({
      message: i18n("avatar_frames.admin.revoke_confirm", {
        username: grant.user.username,
        name: frameName(this.frame),
      }),
      didConfirm: async () => {
        try {
          await ajax(`${this.baseUrl}/grants/${grant.user.id}`, {
            type: "DELETE",
          });
          if (this.grants.length === 1 && this.offset > 0) {
            this.offset -= 50;
          }
          await this.#loadGrants();
        } catch (error) {
          popupAjaxError(error);
        }
      },
    });
  }

  async #loadGrants() {
    this.page = await ajax(`${this.baseUrl}/grants`, {
      data: { offset: this.offset, username: this.search },
    });
  }

  #schedulePoll() {
    cancel(this.#poll);
    this.#poll = later(this, this.#refreshImports, 2000);
  }

  async #refreshImports() {
    try {
      const result = await ajax(`${this.baseUrl}/imports`);
      if (this.isDestroying) {
        return;
      }
      this.importList = result.imports;
      if (
        this.imports.some((item) =>
          ["queued", "processing"].includes(item.status)
        )
      ) {
        this.#schedulePoll();
      } else {
        await this.#loadGrants();
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <DBreadcrumbsItem
      @label={{i18n "avatar_frames.admin.frames"}}
      @route="adminPlugins.show.avatar-frames"
    />
    <DBreadcrumbsItem @label={{frameName this.frame}} />
    <BackButton @route="adminPlugins.show.avatar-frames" />
    <div class="avatar-frame-admin">
      <AdminConfigAreaCard
        @description="avatar_frames.admin.grant_help"
        @translatedHeading={{frameName this.frame}}
      >
        <:content>
          <img
            alt=""
            class="avatar-frame-admin__preview"
            src={{this.frame.static_url}}
          />
          {{#if this.notice}}<p role="status">{{this.notice}}</p>{{/if}}
          {{#if this.frame.enabled}}
            <Form
              @data={{hash user=(array)}}
              @onSubmit={{this.grant}}
              as |form|
            >
              <form.Field
                @name="user"
                @title={{i18n "avatar_frames.admin.recipient"}}
                @type="custom"
                @validation="required"
                as |field|
              >
                <field.Control><UserChooser
                    @id={{field.id}}
                    @onChange={{field.set}}
                    @options={{hash maximum=1 excludeCurrentUser=false}}
                    @value={{field.value}}
                  /></field.Control>
              </form.Field>
              <form.Submit @label="avatar_frames.admin.award" />
            </Form>
          {{else}}<p>{{i18n "avatar_frames.admin.disabled_help"}}</p>{{/if}}
        </:content>
      </AdminConfigAreaCard>
      <AdminConfigAreaCard
        @description="avatar_frames.admin.csv_help"
        @heading="avatar_frames.admin.csv"
      >
        <:content>
          {{#if this.frame.enabled}}
            <Form @onSubmit={{this.importCsv}} as |form|>
              <form.Field
                @name="file"
                @title={{i18n "avatar_frames.admin.csv_file"}}
                @type="custom"
                @validation="required"
                as |field|
              >
                <field.Control>
                  <DPickFilesButton
                    @acceptedFormatsOverride=".csv"
                    @label="avatar_frames.admin.pick_csv"
                    @onFilesPicked={{fn this.pickCsv field.set}}
                    @showButton={{true}}
                  />
                  <span>{{field.value.name}}</span>
                </field.Control>
              </form.Field>
              <form.Submit
                @disabled={{this.importing}}
                @label="avatar_frames.admin.import"
              />
            </Form>
          {{/if}}
          <div aria-live="polite" class="avatar-frame-admin__imports">
            {{#each this.imports as |item|}}
              <div class="avatar-frame-admin__import">
                <p><strong>{{i18n
                      (concat "avatar_frames.admin.import_status." item.status)
                    }}</strong>
                  ·
                  {{dFormatDate item.created_at}}</p>
                <p>{{i18n
                    "avatar_frames.admin.import_counts"
                    matched=item.matched_count
                    granted=item.granted_count
                    skipped=item.skipped_count
                    unmatched=item.unmatched_count
                    failed=item.failed_count
                    processed=item.processed_count
                  }}</p>
                {{#if item.duplicate_count}}<p>{{i18n
                      "avatar_frames.admin.duplicates"
                      count=item.duplicate_count
                    }}</p>{{/if}}
                {{#if item.unmatched_entries}}
                  <details><summary>{{i18n
                        "avatar_frames.admin.unmatched_details"
                      }}</summary><ul>{{#each
                        item.unmatched_entries
                        as |entry|
                      }}<li>{{entry}}</li>{{/each}}</ul></details>
                {{/if}}
                {{#if item.failures}}
                  <details><summary>{{i18n
                        "avatar_frames.admin.failed_details"
                      }}</summary><ul>{{#each item.failures as |failure|}}<li
                        >{{failure.user_id}}
                          {{failure.message}}</li>{{/each}}</ul></details>
                {{/if}}
              </div>
            {{/each}}
          </div>
        </:content>
      </AdminConfigAreaCard>
      <AdminConfigAreaCard @heading="avatar_frames.admin.owners">
        <:content>
          <p>{{i18n "avatar_frames.admin.owner_count" count=this.total}}</p>
          <Form @onSubmit={{this.filter}} as |form|>
            <form.Field
              @name="username"
              @title={{i18n "avatar_frames.admin.search"}}
              @type="input"
              as |field|
            ><field.Control /></form.Field>
            <form.Submit @label="search.title" />
          </Form>
          <table class="d-table avatar-frame-admin__table">
            <thead><tr><th>{{i18n "avatar_frames.admin.recipient"}}</th><th
                >{{i18n "avatar_frames.admin.awarded_by"}}</th><th>{{i18n
                    "avatar_frames.admin.awarded_at"
                  }}</th><th>{{i18n
                    "avatar_frames.admin.actions"
                  }}</th></tr></thead>
            <tbody>
              {{#each this.grants as |grant|}}
                <tr class="d-table__row">
                  <td
                    class="d-table__cell"
                    data-label={{i18n "avatar_frames.admin.recipient"}}
                  >{{dAvatar grant.user imageSize="small"}}
                    {{grant.user.username}}</td>
                  <td
                    class="d-table__cell"
                    data-label={{i18n "avatar_frames.admin.awarded_by"}}
                  >{{grant.granted_by.username}}</td>
                  <td
                    class="d-table__cell"
                    data-label={{i18n "avatar_frames.admin.awarded_at"}}
                  >{{dFormatDate grant.granted_at}}</td>
                  <td
                    class="d-table__cell"
                    data-label={{i18n "avatar_frames.admin.actions"}}
                  ><DButton
                      class="btn-danger btn-small"
                      @action={{fn this.revoke grant}}
                      @label="avatar_frames.admin.revoke"
                    /></td>
                </tr>
              {{else}}<tr><td colspan="4">{{i18n
                      "avatar_frames.admin.no_owners"
                    }}</td></tr>{{/each}}
            </tbody>
          </table>
          <div class="avatar-frame-admin__actions">
            <DButton
              class="btn-default"
              @action={{fn this.turnPage -1}}
              @disabled={{not (gt this.offset 0)}}
              @label="avatar_frames.admin.previous"
            />
            <DButton
              class="btn-default"
              @action={{fn this.turnPage 1}}
              @disabled={{not this.hasNext}}
              @label="avatar_frames.admin.next"
            />
          </div>
        </:content>
      </AdminConfigAreaCard>
    </div>
  </template>
}
