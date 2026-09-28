import Component from "@glimmer/component";
import { themePrefix } from "virtual:theme";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

const CARDS = [
  { key: "learning_resources", icon: "book-open", tone: "blue" },
  { key: "courses", icon: "graduation-cap", tone: "violet" },
  { key: "careers", icon: "briefcase", tone: "amber" },
  { key: "resume", icon: "file-lines", tone: "mint" },
  { key: "campus_services", icon: "building-columns", tone: "sky" },
  { key: "student_identity", icon: "id-card", tone: "rose" },
  { key: "library", icon: "database", tone: "indigo" },
  { key: "alumni", icon: "user-group", tone: "teal" },
];

export default class ISBFV2Workbench extends Component {
  get cards() {
    return CARDS.map((card) => ({
      ...card,
      label: i18n(themePrefix(`isbf_v2.workbench_${card.key}`)),
    }));
  }

  <template>
    <main class="isbf-v2-feature isbf-v2-workbench">
      <p class="isbf-v2-feature__eyebrow">{{i18n
          (themePrefix "isbf_v2.workbench_eyebrow")
        }}</p>
      <h1>{{i18n (themePrefix "isbf_v2.workbench")}}</h1>
      <p class="isbf-v2-feature__intro">{{i18n
          (themePrefix "isbf_v2.workbench_intro")
        }}</p>
      <section
        aria-label={{i18n (themePrefix "isbf_v2.workbench_modules")}}
        class="isbf-v2-workbench__panel"
      >
        <h2>{{i18n (themePrefix "isbf_v2.workbench_modules")}}</h2>
        <div class="isbf-v2-workbench__grid">
          {{#each this.cards as |card|}}
            <div class="isbf-v2-workbench__card">
              <span
                aria-hidden="true"
                class="isbf-v2-workbench__icon isbf-v2-workbench__icon--{{card.tone}}"
              >{{dIcon card.icon}}</span>
              <span class="isbf-v2-workbench__name">{{card.label}}</span>
              <span class="isbf-v2-workbench__status">{{i18n
                  (themePrefix "isbf_v2.workbench_pending")
                }}</span>
            </div>
          {{/each}}
        </div>
      </section>
    </main>
  </template>
}
