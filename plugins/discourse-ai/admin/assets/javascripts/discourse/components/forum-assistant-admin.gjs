import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import AdminConfigAreaCard from "discourse/admin/components/admin-config-area-card";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";

export default class ForumAssistantAdmin extends Component {
  @tracked loading = false;
  @tracked page = 0;
  @tracked filters = { username: "" };
  @tracked result = null;
  @tracked notice = "";

  get data() {
    return this.result ?? this.args.model;
  }

  get rows() {
    return (this.data.requests ?? []).map((request) => ({
      ...request,
      outcome: i18n(`discourse_ai.forum_assistant.statuses.${request.status}`),
      questionUrl: request.post_id ? `/p/${request.post_id}` : null,
      createdAt: new Date(request.created_at).toLocaleString(),
    }));
  }

  @action
  async search(data) {
    this.filters = { username: data.username.trim() };
    this.page = 0;
    await this.load();
  }

  @action
  async changePage(direction) {
    this.page = Math.max(0, this.page + direction);
    await this.load();
  }

  @action
  async load() {
    this.loading = true;
    try {
      this.result = await ajax(
        "/admin/plugins/discourse-ai/forum-assistant.json",
        {
          data: { ...this.filters, page: this.page },
        }
      );
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  async clearCooldown(userId) {
    try {
      await ajax(
        `/admin/plugins/discourse-ai/forum-assistant/cooldown/${userId}.json`,
        { method: "DELETE" }
      );
      this.notice = i18n("discourse_ai.forum_assistant.cooldown_cleared");
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <section class="admin-forum-assistant" ...attributes>
      <DPageSubheader
        @descriptionLabel={{i18n
          "discourse_ai.forum_assistant.admin_description"
        }}
        @titleLabel={{i18n "discourse_ai.forum_assistant.admin_title"}}
      />
      <p><a href="/admin/plugins/discourse-ai/ai-features/7/edit">{{i18n
            "discourse_ai.forum_assistant.settings_link"
          }}</a></p>
      <AdminConfigAreaCard>
        <:content>
          <p>{{i18n
              "discourse_ai.forum_assistant.global_usage"
              used=this.data.global_used
              limit=this.data.global_limit
            }}</p>
          <Form @data={{this.filters}} @onSubmit={{this.search}} as |form|>
            <form.Field
              @name="username"
              @title={{i18n "discourse_ai.forum_assistant.username"}}
              @type="input"
              as |field|
            >
              <field.Control maxlength="60" />
            </form.Field>
            <form.Actions><form.Submit
                @label="discourse_ai.forum_assistant.search"
              /></form.Actions>
          </Form>
          {{#if this.notice}}<p role="status">{{this.notice}}</p>{{/if}}
        </:content>
      </AdminConfigAreaCard>
      {{#if this.rows.length}}
        <div class="admin-forum-assistant__table">
          <table class="grid">
            <thead><tr>
                <th scope="col">{{i18n
                    "discourse_ai.forum_assistant.created_at"
                  }}</th>
                <th scope="col">{{i18n
                    "discourse_ai.forum_assistant.user"
                  }}</th>
                <th scope="col">{{i18n
                    "discourse_ai.forum_assistant.outcome"
                  }}</th>
                <th scope="col">{{i18n
                    "discourse_ai.forum_assistant.sources"
                  }}</th>
                <th scope="col">{{i18n
                    "discourse_ai.forum_assistant.tokens"
                  }}</th>
                <th scope="col">{{i18n
                    "discourse_ai.forum_assistant.question"
                  }}</th>
                <th scope="col">{{i18n
                    "discourse_ai.forum_assistant.clear_cooldown"
                  }}</th>
              </tr></thead>
            <tbody>
              {{#each this.rows as |request|}}
                <tr>
                  <td>{{request.createdAt}}</td>
                  <td>{{request.username}}</td>
                  <td>{{request.outcome}}</td>
                  <td>{{request.source_refs.length}}</td>
                  <td>{{request.input_tokens}} / {{request.output_tokens}}</td>
                  <td>{{#if request.questionUrl}}<a
                        href={{request.questionUrl}}
                      >{{i18n
                          "discourse_ai.forum_assistant.question"
                        }}</a>{{/if}}</td>
                  <td><DButton
                      class="btn-flat"
                      @action={{fn this.clearCooldown request.user_id}}
                      @label="discourse_ai.forum_assistant.clear_cooldown"
                    /></td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{else}}
        <p>{{i18n "discourse_ai.forum_assistant.empty"}}</p>
      {{/if}}
      <DButton
        class="btn-default"
        @action={{fn this.changePage -1}}
        @disabled={{if this.loading true (if this.page false true)}}
        @label="discourse_ai.forum_assistant.previous"
      />
      <DButton
        class="btn-default"
        @action={{fn this.changePage 1}}
        @disabled={{if this.loading true (if this.data.has_more false true)}}
        @label="discourse_ai.forum_assistant.next"
      />
    </section>
  </template>
}
