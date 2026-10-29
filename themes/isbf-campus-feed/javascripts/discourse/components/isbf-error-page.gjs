import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash, uniqueId } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { themePrefix } from "virtual:theme";
import { mountElasticStatus } from "discourse/lib/elastic-status";
import DButton from "discourse/ui-kit/d-button";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { i18n } from "discourse-i18n";
import ISBFV2Brand from "./isbf-v2-brand";

const activePages = new Set();

const pageFrame = modifier((element, [announce]) => {
  activePages.add(element);
  element.ownerDocument.body.classList.add("isbf-error-page-active");
  announce();

  return () => {
    activePages.delete(element);
    if (!activePages.size) {
      element.ownerDocument.body.classList.remove("isbf-error-page-active");
    }
  };
});

const elasticStatus = modifier((element, [{ text }]) => {
  const controller = new AbortController();
  let disposed = false;
  let destroy;

  mountElasticStatus(element, { text, signal: controller.signal })
    .then((cleanup) => {
      if (disposed) {
        cleanup();
      } else {
        destroy = cleanup;
      }
    })
    .catch(() => {
      // Recovery controls and static text remain available if loading fails.
    });

  return () => {
    controller.abort();
    disposed = true;
    destroy?.();
  };
});

export default class ISBFErrorPage extends Component {
  @service a11y;
  @service interfaceColor;

  @tracked detailsError;

  get statusCode() {
    if (this.args.controller.isNetwork) {
      return;
    }
    const status = Number(this.args.controller.thrown?.status);
    if (Number.isInteger(status) && status >= 400 && status <= 599) {
      return status;
    }
  }

  get statusLabel() {
    return this.statusCode
      ? String(this.statusCode)
      : i18n(
          themePrefix(
            this.args.controller.isNetwork
              ? "error_page.offline"
              : "error_page.unknown"
          )
        );
  }

  get description() {
    const controller = this.args.controller;
    if (
      controller.isServer &&
      !controller.thrown?.desc &&
      !controller.networkFixed
    ) {
      return i18n(themePrefix("error_page.server_description"));
    }
    return controller.desc;
  }

  get recoveryButtons() {
    const buttons = this.args.controller.enabledButtons;
    return buttons.map((button, index) => ({
      ...button,
      classes:
        index === buttons.length - 1
          ? "btn-primary isbf-error-page__primary"
          : "btn-flat isbf-error-page__secondary",
    }));
  }

  get detailsExpanded() {
    return (
      Boolean(this.detailsError) &&
      this.detailsError === this.args.controller.thrown
    );
  }

  @action
  announce() {
    this.a11y.announce(this.args.controller.reason, "assertive");
  }

  @action
  toggleDetails() {
    this.detailsError = this.detailsExpanded
      ? null
      : this.args.controller.thrown;
  }

  <template>
    {{#let (uniqueId) (uniqueId) as |titleId detailsId|}}
      <section
        aria-labelledby={{titleId}}
        class="isbf-error-page"
        data-error-status={{this.statusLabel}}
        ...attributes
        {{pageFrame this.announce}}
      >
        <ISBFV2Brand class="isbf-error-page__brand" @compact={{false}} />

        <div class="isbf-error-page__scene">
          <div
            aria-hidden="true"
            class="isbf-error-page__stage"
            {{elasticStatus
              (hash
                text=this.statusLabel colorMode=this.interfaceColor.colorMode
              )
            }}
          >
            <div
              class={{dConcatClass
                "isbf-error-page__fallback"
                (unless this.statusCode "--word")
              }}
            >{{this.statusLabel}}</div>
            <canvas class="isbf-error-page__canvas" data-canvas></canvas>
            <canvas
              class="isbf-error-page__elastic-canvas"
              data-elastic-canvas
              hidden
            ></canvas>
          </div>
        </div>

        <div class="isbf-error-page__message">
          <h1 class="isbf-error-page__title" id={{titleId}}>
            {{@controller.reason}}
          </h1>
          <p class="isbf-error-page__description">{{this.description}}</p>
          <div
            aria-busy={{@controller.loading}}
            class="isbf-error-page__actions"
          >
            {{#each this.recoveryButtons as |button|}}
              <DButton
                class={{button.classes}}
                @action={{button.action}}
                @disabled={{@controller.loading}}
                @icon={{button.icon}}
                @label={{button.key}}
              />
            {{/each}}
          </div>

          <DButton
            class="btn-flat isbf-error-page__details-toggle"
            @action={{this.toggleDetails}}
            @ariaControls={{detailsId}}
            @ariaExpanded={{this.detailsExpanded}}
            @label={{themePrefix "error_page.details"}}
          />
          {{#if this.detailsExpanded}}
            <dl class="isbf-error-page__details" id={{detailsId}}>
              <dt>{{i18n (themePrefix "error_page.status")}}</dt>
              <dd>{{this.statusLabel}}</dd>
              {{#if @controller.requestUrl}}
                <dt>{{i18n (themePrefix "error_page.request")}}</dt>
                <dd><code>{{@controller.requestUrl}}</code></dd>
              {{/if}}
            </dl>
          {{/if}}
        </div>
      </section>
    {{/let}}
  </template>
}
