import Component from "@glimmer/component";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import {
  marketplaceDetailImages,
  marketplaceImageUrl,
  marketplacePrice,
} from "../lib/marketplace";
import { plainText } from "../lib/post-card-helpers";
import contentImages from "../modifiers/content-images";

export class ISBFMarketplacePrice extends Component {
  get post() {
    return this.args.outletArgs?.post;
  }

  get metadata() {
    return (
      this.args.metadata ??
      this.post?.isbf_marketplace ??
      this.post?.topic?.isbf_marketplace
    );
  }

  get price() {
    if (this.post && this.post.post_number !== 1) {
      return null;
    }
    return marketplacePrice(this.metadata?.price_cents);
  }

  get images() {
    if (this.post?.post_number !== 1 || !this.metadata) {
      return [];
    }
    const body = document.createElement("div");
    body.innerHTML = this.post.cooked || "";
    const sources = [...body.querySelectorAll("img[src]")].map((image) =>
      image.getAttribute("src"),
    );
    return marketplaceDetailImages(this.metadata, sources);
  }

  <template>
    {{#if this.images.length}}
      <div class="isbf-marketplace-detail-images" {{contentImages}}>
        {{#each this.images key="id" as |image|}}
          <a
            aria-label={{i18n (themePrefix "isbf_v2.preview_image")}}
            class="lightbox"
            href={{image.url}}
          ><img
              alt={{this.post.topic.title}}
              loading="lazy"
              src={{image.thumbnail}}
            /></a>
        {{/each}}
      </div>
    {{/if}}
    {{#if this.price}}<span
        class="isbf-marketplace-price"
      >{{this.price}}</span>{{/if}}
  </template>
}

export default class ISBFMarketplaceCard extends Component {
  get image() {
    const image = this.args.topic.isbf_marketplace?.images?.[0];
    return marketplaceImageUrl(image?.thumbnail_url) || this.imageUrl;
  }

  get imageUrl() {
    return marketplaceImageUrl(
      this.args.topic.isbf_marketplace?.images?.[0]?.url,
    );
  }

  get description() {
    return plainText(
      this.args.topic.isbf_marketplace?.description ?? this.args.topic.excerpt,
    );
  }

  <template>
    <article class="isbf-marketplace-card" {{contentImages}}>
      {{#if this.imageUrl}}
        <a
          aria-label={{i18n (themePrefix "isbf_v2.preview_image")}}
          class="lightbox isbf-marketplace-card__image"
          href={{this.imageUrl}}
        ><img alt={{@topic.title}} loading="lazy" src={{this.image}} /></a>
      {{else}}
        <span aria-hidden="true" class="isbf-marketplace-card__image">
          {{#if this.image}}<img
              alt=""
              loading="lazy"
              src={{this.image}}
            />{{/if}}
        </span>
      {{/if}}
      <a class="isbf-marketplace-card__content" href={{@topic.url}}>
        <strong class="isbf-marketplace-card__title">{{@topic.title}}</strong>
        <span
          class="isbf-marketplace-card__description"
        >{{this.description}}</span>
        <ISBFMarketplacePrice @metadata={{@topic.isbf_marketplace}} />
      </a>
    </article>
  </template>
}
