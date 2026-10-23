import Component from "@glimmer/component";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import { themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { alumniConfig } from "../lib/alumni";
import { careersConfig } from "../lib/careers";
import { learningConfig, libraryConfig } from "../lib/learning-resources";
import { marketplaceConfig } from "../lib/marketplace";
import { teamupConfig } from "../lib/teamup";
import ISBFV2MoreMenu from "./isbf-v2-more-menu";

const CARDS = [
  { key: "learning_resources", icon: "book-open", tone: "blue" },
  { key: "library", icon: "database", tone: "indigo" },
  { key: "courses", icon: "graduation-cap", tone: "violet" },
  { key: "careers", icon: "briefcase", tone: "amber" },
  { key: "resume", icon: "file-lines", tone: "mint" },
  { key: "campus_services", icon: "building-columns", tone: "sky" },
  { key: "student_identity", icon: "id-card", tone: "rose" },
  { key: "alumni", icon: "user-group", tone: "teal" },
  { key: "marketplace", icon: "bag-shopping", tone: "amber" },
  { key: "teamup", icon: "user-group", tone: "violet" },
];

const profiles = {
  learning_resources: {
    duration: 360,
    keyframes: [
      { transform: "rotate(0deg) scale(1)", offset: 0 },
      { transform: "rotate(-8deg) scale(1.12)", offset: 0.4 },
      { transform: "rotate(0deg) scale(1)", offset: 1 },
    ],
  },
  courses: {
    duration: 380,
    keyframes: [
      { transform: "translateY(0) rotate(0deg)", offset: 0 },
      { transform: "translateY(-4px) rotate(5deg)", offset: 0.4 },
      { transform: "translateY(0) rotate(0deg)", offset: 1 },
    ],
  },
  careers: {
    duration: 380,
    keyframes: [
      { transform: "rotate(0deg)", offset: 0 },
      { transform: "rotate(-7deg)", offset: 0.4 },
      { transform: "rotate(4deg)", offset: 0.7 },
      { transform: "rotate(0deg)", offset: 1 },
    ],
  },
  resume: {
    duration: 320,
    keyframes: [
      { transform: "translateY(0) rotate(0deg)", offset: 0 },
      { transform: "translateY(-4px) rotate(-4deg)", offset: 0.4 },
      { transform: "translateY(0) rotate(0deg)", offset: 1 },
    ],
  },
  campus_services: {
    duration: 360,
    keyframes: [
      { transform: "translateY(0) scale(1)", offset: 0 },
      { transform: "translateY(-2px) scale(1.1)", offset: 0.4 },
      { transform: "translateY(0) scale(1)", offset: 1 },
    ],
  },
  student_identity: {
    duration: 340,
    keyframes: [
      { transform: "rotate(0deg) scale(1)", offset: 0 },
      { transform: "rotate(5deg) scale(1.08)", offset: 0.4 },
      { transform: "rotate(0deg) scale(1)", offset: 1 },
    ],
  },
  library: {
    duration: 360,
    keyframes: [
      { transform: "translateY(0) scaleY(1)", offset: 0 },
      { transform: "translateY(-3px) scaleY(1.1)", offset: 0.4 },
      { transform: "translateY(0) scaleY(1)", offset: 1 },
    ],
  },
  alumni: {
    duration: 320,
    keyframes: [
      { transform: "scale(1)", offset: 0 },
      { transform: "scale(1.14)", offset: 0.4 },
      { transform: "scale(1)", offset: 1 },
    ],
  },
  teamup: {
    duration: 320,
    keyframes: [
      { transform: "translateX(0)", offset: 0 },
      { transform: "translateX(-3px)", offset: 0.3 },
      { transform: "translateX(3px)", offset: 0.65 },
      { transform: "translateX(0)", offset: 1 },
    ],
  },
  marketplace: {
    duration: 400,
    keyframes: [
      { transform: "rotate(0deg)", offset: 0 },
      { transform: "rotate(-10deg)", offset: 0.25 },
      { transform: "rotate(7deg)", offset: 0.5 },
      { transform: "rotate(-3deg)", offset: 0.75 },
      { transform: "rotate(0deg)", offset: 1 },
    ],
  },
};
const fallback = {
  duration: 320,
  keyframes: [
    { transform: "scale(1)", offset: 0 },
    { transform: "scale(1.1)", offset: 0.4 },
    { transform: "scale(1)", offset: 1 },
  ],
};

let nextSpriteId = 0;

const iconFeedback = modifier((element) => {
  const media = window.matchMedia("(prefers-reduced-motion: reduce)");
  const controller = new AbortController();
  const animations = new Map();
  const pointerTypes = new WeakMap();
  const listen = (target, type, callback, options = {}) =>
    target.addEventListener(type, callback, {
      ...options,
      signal: controller.signal,
    });
  const iconFor = (card) =>
    card.querySelector(".isbf-v2-workbench__icon .d-icon");

  const bagUse = element.querySelector(
    '[data-service="marketplace"] .d-icon use'
  );
  const originalHref = bagUse?.getAttribute("href");
  let sprite;
  let spriteObserver;

  function repairBag() {
    if (controller.signal.aborted || sprite || !bagUse) {
      return Boolean(sprite);
    }
    const source = originalHref?.startsWith("#")
      ? document.getElementById(originalHref.slice(1))
      : null;
    if (source?.tagName.toLowerCase() !== "symbol") {
      return false;
    }
    sprite = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    sprite.classList.add("isbf-v2-workbench__sprite");
    sprite.setAttribute("aria-hidden", "true");
    const symbol = source.cloneNode(true);
    symbol.id = `isbf-workbench-bag-${++nextSpriteId}`;
    // The upstream handle reaches y=-32, outside its declared viewBox.
    symbol.setAttribute("viewBox", "-16 -48 480 544");
    sprite.appendChild(symbol);
    element.appendChild(sprite);
    bagUse.setAttribute("href", `#${symbol.id}`);
    spriteObserver?.disconnect();
    return true;
  }

  if (!repairBag() && bagUse) {
    // The shared sprite may arrive after the workbench has mounted.
    spriteObserver = new MutationObserver(repairBag);
    spriteObserver.observe(
      document.getElementById("svg-sprites") ?? document.body,
      {
        childList: true,
        subtree: true,
      }
    );
    repairBag();
  }

  function animate(icon, keyframes, duration) {
    animations.get(icon)?.cancel();
    const animation = icon.animate(
      keyframes.map((frame) => ({
        ...frame,
        easing: "cubic-bezier(0.2, 0.8, 0.2, 1)",
      })),
      { duration, iterations: 1 }
    );
    animations.set(icon, animation);
    animation.onfinish = () => {
      if (animations.get(icon) === animation) {
        animations.delete(icon);
      }
    };
  }

  function play(card) {
    const icon = iconFor(card);
    if (media.matches || !icon?.animate) {
      return;
    }
    const profile = Object.hasOwn(profiles, card.dataset.service)
      ? profiles[card.dataset.service]
      : fallback;
    const frames = profile.keyframes.map((frame) => ({ ...frame }));
    frames[0].transform = getComputedStyle(icon).transform;
    animate(icon, frames, profile.duration);
  }

  function restore(card) {
    const icon = iconFor(card);
    if (animations.has(icon)) {
      animate(
        icon,
        [
          { transform: getComputedStyle(icon).transform },
          { transform: "none" },
        ],
        120
      );
    }
  }

  function activeCard(event) {
    const card =
      event.target instanceof Element
        ? event.target.closest("a.isbf-v2-workbench__card[href]")
        : null;
    return card && element.contains(card) ? card : null;
  }

  listen(element, "pointerover", (event) => {
    const card = activeCard(event);
    if (
      card &&
      event.pointerType === "mouse" &&
      !card.contains(event.relatedTarget)
    ) {
      play(card);
    }
  });
  listen(
    element,
    "pointerdown",
    (event) => {
      const card = activeCard(event);
      if (card) {
        pointerTypes.set(card, event.pointerType);
      }
    },
    { passive: true }
  );
  listen(element, "click", (event) => {
    const card = activeCard(event);
    const type = event.pointerType || pointerTypes.get(card);
    if (card && (event.detail === 0 || type === "touch" || type === "pen")) {
      play(card);
    }
  });
  listen(element, "pointerout", (event) => {
    const card = activeCard(event);
    if (
      card &&
      event.pointerType === "mouse" &&
      !card.contains(event.relatedTarget)
    ) {
      restore(card);
    }
  });
  for (const name of ["pointercancel", "focusout"]) {
    listen(element, name, (event) => {
      const card = activeCard(event);
      if (card) {
        restore(card);
      }
    });
  }
  const stop = () => {
    animations.forEach((animation) => animation.cancel());
    animations.clear();
  };
  listen(media, "change", stop);
  listen(window, "pagehide", stop);
  listen(window, "blur", stop);
  listen(document, "visibilitychange", () => {
    if (document.hidden) {
      stop();
    }
  });
  return () => {
    controller.abort();
    spriteObserver?.disconnect();
    stop();
    if (bagUse && originalHref) {
      bagUse.setAttribute("href", originalHref);
    }
    sprite?.remove();
  };
});

export default class ISBFV2Workbench extends Component {
  @service site;
  @service siteSettings;

  get cards() {
    return CARDS.filter(
      (card) => card.key !== "alumni" || alumniConfig(this.site)
    ).map((card) => ({
      ...card,
      label: i18n(themePrefix(`isbf_v2.workbench_${card.key}`)),
      href:
        card.key === "learning_resources" && learningConfig(this.site)
          ? "/isbf/learning"
          : card.key === "library" && libraryConfig(this.site)
            ? "/isbf/library"
            : card.key === "careers" && careersConfig(this.site)
              ? "/isbf/careers"
              : card.key === "marketplace" && marketplaceConfig(this.site)
                ? "/isbf/marketplace"
                : card.key === "teamup" && teamupConfig(this.site)
                  ? "/isbf/teamup"
                  : card.key === "alumni"
                    ? "/isbf/alumni"
                    : card.key === "resume" &&
                        this.siteSettings.isbf_resume_enabled
                      ? "/isbf/workbench/resume"
                      : null,
    }));
  }

  <template>
    <main class="isbf-v2-feature isbf-v2-workbench" {{iconFeedback this.cards}}>
      <h1>{{i18n (themePrefix "isbf_v2.workbench")}}</h1>
      <section
        aria-label={{i18n (themePrefix "isbf_v2.workbench")}}
        class="isbf-v2-workbench__panel"
      >
        <div class="isbf-v2-workbench__grid">
          {{#each this.cards as |card|}}
            {{#if card.href}}
              <a
                class="isbf-v2-workbench__card"
                data-service={{card.key}}
                href={{card.href}}
              >
                <span
                  aria-hidden="true"
                  class="isbf-v2-workbench__icon isbf-v2-workbench__icon--{{card.tone}}"
                >{{dIcon card.icon}}</span>
                <span class="isbf-v2-workbench__name">{{card.label}}</span>
              </a>
            {{else}}
              <div class="isbf-v2-workbench__card" data-service={{card.key}}>
                <span
                  aria-hidden="true"
                  class="isbf-v2-workbench__icon isbf-v2-workbench__icon--{{card.tone}}"
                >{{dIcon card.icon}}</span>
                <span class="isbf-v2-workbench__name">{{card.label}}</span>
              </div>
            {{/if}}
          {{/each}}
        </div>
      </section>
      <div class="isbf-v2-workbench__more">
        <div class="isbf-v2-workbench__more-control">
          <ISBFV2MoreMenu @workbench={{true}} />
        </div>
      </div>
    </main>
  </template>
}
