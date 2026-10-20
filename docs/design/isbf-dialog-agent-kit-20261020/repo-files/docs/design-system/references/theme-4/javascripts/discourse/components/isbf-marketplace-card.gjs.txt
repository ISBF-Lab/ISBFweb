import Component from "@glimmer/component";
import {
  marketplaceDetailImages,
  marketplaceImageUrl,
  marketplacePrice,
} from "../lib/marketplace";
import { plainText } from "../lib/post-card-helpers";

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
      <div class="isbf-marketplace-detail-images">
        {{#each this.images key="id" as |image|}}
          <a href={{image.url}}><img
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
    const url = image?.thumbnail_url || image?.url;
    return marketplaceImageUrl(url);
  }

  get description() {
    return plainText(
      this.args.topic.isbf_marketplace?.description ?? this.args.topic.excerpt,
    );
  }

  <template>
    <a class="isbf-marketplace-card" href={{@topic.url}}>
      <span aria-hidden="true" class="isbf-marketplace-card__image">
        {{#if this.image}}<img
            alt=""
            loading="lazy"
            src={{this.image}}
          />{{/if}}
      </span>
      <span class="isbf-marketplace-card__content">
        <strong class="isbf-marketplace-card__title">{{@topic.title}}</strong>
        <span
          class="isbf-marketplace-card__description"
        >{{this.description}}</span>
        <ISBFMarketplacePrice @metadata={{@topic.isbf_marketplace}} />
      </span>
    </a>
  </template>
}
