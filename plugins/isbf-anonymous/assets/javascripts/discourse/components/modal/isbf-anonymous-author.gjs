import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import getURL from "discourse/lib/get-url";
import { eq, not, or } from "discourse/truth-helpers";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import { i18n } from "discourse-i18n";

function lookupErrorMessage(error) {
  if (error.jqXHR?.status === 403) {
    return i18n("isbf_anonymous.author_lookup.forbidden");
  }
  if (error.jqXHR?.status === 404) {
    return i18n("isbf_anonymous.author_lookup.unavailable");
  }
  return i18n("isbf_anonymous.author_lookup.failed");
}

export default class IsbfAnonymousAuthor extends Component {
  @service a11y;

  @tracked retryCount = 0;

  @action
  async loadAuthor() {
    const { id, type } = this.args.model;

    try {
      const { author } = await ajax(
        `/isbf-anonymous/api/${type}/${id}/author.json`
      );

      if (!this.isDestroying) {
        this.a11y.announce(
          i18n("isbf_anonymous.author_lookup.loaded", {
            username: author.username,
          })
        );
      }

      return {
        author,
        adminUrl: getURL(
          `/admin/users/${author.id}/${encodeURIComponent(author.username.toLowerCase())}`
        ),
      };
    } catch (error) {
      if (!this.isDestroying) {
        this.a11y.announce(lookupErrorMessage(error), "assertive");
      }
      throw error;
    }
  }

  @action
  retry() {
    this.retryCount++;
  }

  <template>
    <DModal
      class="isbf-anonymous-author"
      @closeModal={{@closeModal}}
      @title={{i18n "isbf_anonymous.author_lookup.title"}}
    >
      <:body>
        <DAsyncContent
          @asyncData={{this.loadAuthor}}
          @context={{this.retryCount}}
        >
          <:content as |result|>
            <div class="isbf-anonymous-author__identity">
              {{dAvatar result.author imageSize="large"}}
              <dl class="isbf-anonymous-author__details">
                <dt>{{i18n "isbf_anonymous.author_lookup.username"}}</dt>
                <dd class="isbf-anonymous-author__username">
                  {{result.author.username}}
                </dd>
                {{#if result.author.name}}
                  <dt>{{i18n "isbf_anonymous.author_lookup.name"}}</dt>
                  <dd>{{result.author.name}}</dd>
                {{/if}}
                <dt>{{i18n "isbf_anonymous.author_lookup.user_id"}}</dt>
                <dd class="isbf-anonymous-author__user-id">
                  {{result.author.id}}
                </dd>
              </dl>
            </div>
            <DButton
              class="btn-primary isbf-anonymous-author__manage"
              @href={{result.adminUrl}}
              @icon="user-gear"
              @label="isbf_anonymous.author_lookup.manage_user"
              {{on "click" @closeModal}}
            />
          </:content>
          <:error as |error|>
            <p class="isbf-anonymous-author__error">
              {{lookupErrorMessage error}}
            </p>
            {{#if
              (not (or (eq error.jqXHR.status 403) (eq error.jqXHR.status 404)))
            }}
              <DButton
                class="btn-default isbf-anonymous-author__retry"
                @action={{this.retry}}
                @icon="rotate"
                @label="isbf_anonymous.author_lookup.retry"
              />
            {{/if}}
          </:error>
        </DAsyncContent>
      </:body>
    </DModal>
  </template>
}
