import { on } from "@ember/modifier";
import { service } from "@ember/service";
import { settings } from "virtual:theme";
import HomeLogo from "discourse/components/header/home-logo";
import Logo from "discourse/components/header/logo";
import getURL from "discourse/lib/get-url";
import { and, notEq } from "discourse/truth-helpers";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";

class BrandImage extends Logo {
  <template>
    <picture class="isbf-v2-brand__image" ...attributes>
      {{#if (and @darkUrl (notEq @url @darkUrl))}}
        <source media={{this.darkMediaQuery}} srcset={{getURL @darkUrl}} />
      {{/if}}
      <img alt="" class="isbf-v2-brand__logo" src={{getURL @url}} />
    </picture>
  </template>
}

export default class ISBFV2Brand extends HomeLogo {
  @service capabilities;

  get isCompact() {
    return (
      !this.args.mobile && (this.args.compact ?? !this.capabilities.viewport.lg)
    );
  }

  get logoName() {
    if (this.args.mobile && this.mobileLogoUrl) {
      return "mobile_logo";
    }
    if (this.isCompact && this.logoSmallUrl) {
      return "logo_small";
    }
    return "logo";
  }

  get imageUrl() {
    return this.logoResolver(this.logoName);
  }

  get imageDarkUrl() {
    return this.logoResolver(this.logoName, { dark: this.darkModeAvailable });
  }

  get title() {
    return settings.brand_name || super.title;
  }

  get hasBrand() {
    return this.showLogo || this.showName;
  }

  get showLogo() {
    return settings.brand_show_logo && Boolean(this.imageUrl);
  }

  get showName() {
    return settings.brand_show_name;
  }

  <template>
    {{#if this.hasBrand}}
      <a
        aria-label={{this.title}}
        class={{dConcatClass "isbf-v2-brand" (if this.isCompact "--compact")}}
        href={{this.href}}
        ...attributes
        {{on "click" this.click}}
      >
        {{#if this.showLogo}}
          <BrandImage @darkUrl={{this.imageDarkUrl}} @url={{this.imageUrl}} />
        {{/if}}
        {{#if this.showName}}
          <span class="isbf-v2-brand__name">{{this.title}}</span>
        {{/if}}
      </a>
    {{/if}}
  </template>
}
