import Component from "@glimmer/component";
import { service } from "@ember/service";
import { getURLWithCDN } from "discourse/lib/get-url";
import { eq } from "discourse/truth-helpers";
import avatarFramePosition from "../modifiers/avatar-frame-position";

export default class AvatarFrameOverlay extends Component {
  @service site;
  @service siteSettings;

  get frame() {
    if (typeof this.args.frame === "object") {
      return this.args.frame;
    }
    if (!this.siteSettings.avatar_frames_enabled) {
      return null;
    }
    return this.site.avatar_frames?.find(
      (frame) => frame.key === this.args.frame
    );
  }

  get imageUrl() {
    return this.args.motion === "static"
      ? this.staticUrl
      : getURLWithCDN(this.frame.image_url);
  }

  get staticUrl() {
    return getURLWithCDN(this.frame.static_url);
  }

  <template>
    {{#if this.frame}}
      <picture
        class="avatar-frame__overlay"
        data-frame={{this.frame.key}}
        data-motion={{if (eq @motion "static") "static" "auto"}}
        {{avatarFramePosition this.frame}}
      >
        <source
          media="(prefers-reduced-motion: reduce)"
          srcset={{this.staticUrl}}
        />
        <img
          alt=""
          class="avatar-frame__image"
          height="288"
          loading="lazy"
          src={{this.imageUrl}}
          width="288"
        />
      </picture>
    {{/if}}
  </template>
}
