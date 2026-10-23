import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import contentImages from "../modifiers/content-images";

export default <template>
  <article class="isbf-marketplace-card" ...attributes {{contentImages}}>
    {{#if @imageUrl}}
      <a
        aria-label={{i18n (themePrefix "isbf_v2.preview_image")}}
        class="lightbox isbf-marketplace-card__image"
        href={{@imageUrl}}
      ><img alt={{@topic.title}} loading="lazy" src={{@image}} /></a>
    {{else}}
      <span aria-hidden="true" class="isbf-marketplace-card__image">
        {{#if @image}}<img alt="" loading="lazy" src={{@image}} />{{/if}}
      </span>
    {{/if}}
    <a class="isbf-marketplace-card__content" href={{@topic.url}}>
      <strong class="isbf-marketplace-card__title">{{@topic.title}}</strong>
      <span class="isbf-marketplace-card__description">{{@description}}</span>
      {{yield}}
    </a>
  </article>
</template>
