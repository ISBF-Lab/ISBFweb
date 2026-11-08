import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { trustHTML } from "@ember/template";
import lightbox from "discourse/lib/lightbox";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import IsbfGuideToc from "./isbf-guide-toc";

export default class IsbfGuideContent extends Component {
  get documents() {
    return [this.args.guide];
  }

  get isHtml() {
    return this.args.guide.content_format === "html";
  }

  get cooked() {
    // Only the server's sanitized published/authorized-preview HTML reaches this renderer.
    return trustHTML(this.args.guide.cooked);
  }

  @action
  async enhanceContent(element) {
    await lightbox(element);
    const fragment = window.location.hash.slice(1);
    if (fragment) {
      const target = element.querySelector(
        `#${CSS.escape(decodeURIComponent(fragment))}`
      );
      target?.scrollIntoView();
    }
  }

  <template>
    <div class="isbf-guide-content">
      {{#if @guide.preview}}
        <p class="isbf-guide-content__preview" role="status">{{i18n
            "isbf_guides.preview_notice"
          }}</p>
      {{/if}}
      <header class="isbf-guide-content__heading">
        <h1>{{@guide.title}}</h1>
        {{#if @guide.summary}}<p
            class="isbf-guide-content__summary"
          >{{@guide.summary}}</p>{{/if}}
        <p class="isbf-guide-content__updated">
          {{i18n "isbf_guides.updated"}}
          <time datetime={{@guide.updated_at}}>{{dFormatDate
              @guide.updated_at
            }}</time>
        </p>
      </header>
      <div class="isbf-guide-content__layout">
        <div class="isbf-guide-content__body">
          {{#if @guide.toc.length}}
            <details class="isbf-guide-content__toc">
              <summary>{{i18n "isbf_guides.contents"}}{{dIcon
                  "chevron-down"
                }}</summary>
              <IsbfGuideToc @entries={{@guide.toc}} />
            </details>
          {{/if}}
          {{#each this.documents key="revision_id"}}
            <article
              class={{dConcatClass
                "isbf-guide-content__article"
                (if this.isHtml "isbf-guide-document" "cooked")
              }}
              {{didInsert this.enhanceContent}}
            >
              {{this.cooked}}
            </article>
          {{/each}}
        </div>
      </div>
    </div>
  </template>
}
