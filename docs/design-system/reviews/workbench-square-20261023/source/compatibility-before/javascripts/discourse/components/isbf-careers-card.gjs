import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { careersImageUrl, careersSalary } from "../lib/careers";
import { loadCookedPost } from "../lib/feed-post-loader";
import { plainText } from "../lib/post-card-helpers";
import { postPreview } from "../lib/post-preview";
import ISBFWorkbenchListingCard from "./isbf-workbench-listing-card";

export class ISBFCareersSalary extends Component {
  get salary() {
    const post = this.args.outletArgs?.post;
    if (post && post.post_number !== 1) {
      return "";
    }
    return careersSalary(
      (this.args.metadata ?? post?.isbf_careers ?? post?.topic?.isbf_careers)
        ?.salary
    );
  }

  <template>
    {{#if this.salary}}<span
        class="isbf-careers-salary"
      >{{this.salary}}</span>{{/if}}
  </template>
}

export default class ISBFCareersCard extends Component {
  @service currentUser;

  @tracked previewImage = null;

  #imageOwner;
  #imageUserId;
  #request = 0;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#request++;
  }

  get description() {
    return plainText(
      this.args.topic.isbf_careers?.description || this.args.topic.excerpt
    );
  }

  get image() {
    return (
      careersImageUrl(this.args.topic.image_url) ||
      (this.#imageOwner === this.args.topic &&
      this.#imageUserId === this.currentUser?.id
        ? this.previewImage
        : null)
    );
  }

  @action
  async loadImage() {
    const topic = this.args.topic;
    const postId = Number(topic.first_post_id);
    const userId = this.currentUser?.id;
    const request = ++this.#request;
    this.previewImage = null;
    this.#imageOwner = topic;
    this.#imageUserId = userId;
    if (
      careersImageUrl(topic.image_url) ||
      !userId ||
      !Number.isSafeInteger(postId) ||
      postId <= 0 ||
      topic.hidden
    ) {
      return;
    }
    try {
      const cooked = await loadCookedPost(postId);
      if (
        !this.isDestroying &&
        request === this.#request &&
        this.args.topic === topic &&
        this.currentUser?.id === userId &&
        Number(topic.first_post_id) === postId &&
        !topic.hidden
      ) {
        this.previewImage = careersImageUrl(postPreview(cooked).images[0]?.src);
      }
    } catch {
      // The native topic link remains usable when a cover cannot be loaded.
    }
  }

  <template>
    <ISBFWorkbenchListingCard
      class="isbf-careers-card"
      @description={{this.description}}
      @image={{this.image}}
      @imageUrl={{this.image}}
      @topic={{@topic}}
      {{didInsert this.loadImage}}
      {{didUpdate
        this.loadImage
        @topic
        @topic.image_url
        @topic.first_post_id
        @topic.hidden
        this.currentUser.id
      }}
    >
      <ISBFCareersSalary @metadata={{@topic.isbf_careers}} />
    </ISBFWorkbenchListingCard>
  </template>
}
