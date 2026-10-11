import Component from "@glimmer/component";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { alumniConfig } from "../lib/alumni";
import { learningConfig } from "../lib/learning-resources";
import { marketplaceConfig } from "../lib/marketplace";
import ISBFV2MoreMenu from "./isbf-v2-more-menu";

const CARDS = [
  { key: "learning_resources", icon: "book-open", tone: "blue" },
  { key: "courses", icon: "graduation-cap", tone: "violet" },
  { key: "careers", icon: "briefcase", tone: "amber" },
  { key: "resume", icon: "file-lines", tone: "mint" },
  { key: "campus_services", icon: "building-columns", tone: "sky" },
  { key: "student_identity", icon: "id-card", tone: "rose" },
  { key: "library", icon: "database", tone: "indigo" },
  { key: "alumni", icon: "user-group", tone: "teal" },
  { key: "marketplace", icon: "bag-shopping", tone: "amber" },
];

export default class ISBFV2Workbench extends Component {
  @service site;

  get cards() {
    return CARDS.filter(
      (card) => card.key !== "alumni" || alumniConfig(this.site),
    ).map((card) => ({
      ...card,
      label: i18n(themePrefix(`isbf_v2.workbench_${card.key}`)),
      href:
        card.key === "learning_resources" && learningConfig(this.site)
          ? "/isbf/learning"
          : card.key === "marketplace" && marketplaceConfig(this.site)
            ? "/isbf/marketplace"
            : card.key === "alumni"
              ? "/isbf/alumni"
              : null,
    }));
  }

  <template>
    <main class="isbf-v2-feature isbf-v2-workbench">
      <h1>{{i18n (themePrefix "isbf_v2.workbench")}}</h1>
      <section
        aria-label={{i18n (themePrefix "isbf_v2.workbench")}}
        class="isbf-v2-workbench__panel"
      >
        <div class="isbf-v2-workbench__grid">
          {{#each this.cards as |card|}}
            {{#if card.href}}
              <a class="isbf-v2-workbench__card" href={{card.href}}>
                <span
                  aria-hidden="true"
                  class="isbf-v2-workbench__icon isbf-v2-workbench__icon--{{card.tone}}"
                >{{dIcon card.icon}}</span>
                <span class="isbf-v2-workbench__name">{{card.label}}</span>
              </a>
            {{else}}
              <div class="isbf-v2-workbench__card">
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
