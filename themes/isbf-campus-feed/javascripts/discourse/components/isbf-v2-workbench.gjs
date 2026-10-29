import Component from "@glimmer/component";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { i18n } from "discourse-i18n";
import { alumniConfig } from "../lib/alumni";
import { careersConfig } from "../lib/careers";
import { learningConfig, libraryConfig } from "../lib/learning-resources";
import { marketplaceConfig } from "../lib/marketplace";
import { mbtiConfig } from "../lib/mbti";
import { teamupConfig } from "../lib/teamup";
import ISBFV2MoreMenu from "./isbf-v2-more-menu";
import ISBFWorkbenchGrid from "./isbf-workbench-grid";

const CARDS = [
  {
    key: "learning_resources",
    icon: "isbf-workbench-book-open",
    mobileIcon: "book-open",
    tone: "blue",
  },
  {
    key: "library",
    icon: "isbf-workbench-database",
    mobileIcon: "database",
    tone: "indigo",
  },
  {
    key: "courses",
    icon: "isbf-workbench-graduation-cap",
    mobileIcon: "graduation-cap",
    tone: "violet",
  },
  {
    key: "careers",
    icon: "isbf-workbench-briefcase",
    mobileIcon: "briefcase",
    tone: "amber",
  },
  {
    key: "resume",
    icon: "isbf-workbench-file-lines",
    mobileIcon: "file-lines",
    tone: "mint",
  },
  {
    key: "campus_services",
    icon: "isbf-workbench-building-columns",
    mobileIcon: "building-columns",
    tone: "sky",
  },
  {
    key: "student_identity",
    icon: "isbf-workbench-id-card",
    mobileIcon: "id-card",
    tone: "rose",
  },
  {
    key: "alumni",
    icon: "isbf-workbench-user-group",
    mobileIcon: "user-group",
    tone: "teal",
  },
  {
    key: "marketplace",
    icon: "isbf-workbench-bag-shopping",
    mobileIcon: "bag-shopping",
    tone: "amber",
  },
  {
    key: "teamup",
    icon: "isbf-workbench-user-group",
    mobileIcon: "user-group",
    tone: "violet",
  },
  { key: "mbti", icon: "brain", mobileIcon: "brain", tone: "blue" },
];

export default class ISBFV2Workbench extends Component {
  @service site;
  @service siteSettings;

  get cards() {
    return CARDS.filter(
      (card) =>
        (card.key !== "alumni" || alumniConfig(this.site)) &&
        (card.key !== "mbti" || mbtiConfig(this.site))
    ).map((card) => ({
      ...card,
      label: i18n(themePrefix(`isbf_v2.workbench_${card.key}`)),
      href:
        card.key === "mbti"
          ? "/isbf/mbti"
          : card.key === "learning_resources" && learningConfig(this.site)
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
    <main class="isbf-v2-feature isbf-v2-workbench">
      <header class="isbf-v2-workbench__heading">
        <h1>{{i18n (themePrefix "isbf_v2.workbench")}}</h1>
      </header>
      <section
        aria-label={{i18n (themePrefix "isbf_v2.workbench")}}
        class="isbf-v2-workbench__panel"
      >
        <ISBFWorkbenchGrid @cards={{this.cards}} />
      </section>
      <div class="isbf-v2-workbench__more">
        <div class="isbf-v2-workbench__more-control">
          <ISBFV2MoreMenu @workbench={{true}} />
        </div>
      </div>
    </main>
  </template>
}
