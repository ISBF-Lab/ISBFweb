import Component from "@glimmer/component";
import { service } from "@ember/service";
import { settings, themePrefix } from "virtual:theme";
import { isExistingIconId } from "discourse/lib/icon-library";
import { i18n } from "discourse-i18n";
import { alumniConfig } from "../lib/alumni";
import { careersConfig } from "../lib/careers";
import { learningConfig, libraryConfig } from "../lib/learning-resources";
import { marketplaceConfig } from "../lib/marketplace";
import { mbtiConfig } from "../lib/mbti";
import { teamupConfig } from "../lib/teamup";
import { mergeWorkbenchEntries } from "../lib/workbench-entries";
import ISBFV2MoreMenu from "./isbf-v2-more-menu";
import ISBFWorkbenchGrid from "./isbf-workbench-grid";

export default class ISBFV2Workbench extends Component {
  @service currentUser;
  @service site;
  @service siteSettings;

  get cards() {
    return mergeWorkbenchEntries(settings.workbench_entries, isExistingIconId)
      .filter(
        (card) =>
          (card.key !== "alumni" || alumniConfig(this.site)) &&
          (card.key !== "mbti" || mbtiConfig(this.site)) &&
          (card.key !== "ai_assistant" ||
            (this.currentUser?.forum_assistant?.enabled &&
              this.currentUser?.forum_assistant?.configured)) &&
          (card.key !== "guides" || this.siteSettings.isbf_guides_enabled)
      )
      .map((card) => ({
        ...card,
        label: i18n(themePrefix(`isbf_v2.workbench_${card.key}`)),
        href:
          card.key === "mbti"
            ? "/isbf/mbti"
            : card.key === "ai_assistant"
              ? "/discourse-ai/ai-bot/conversations"
              : card.key === "guides"
                ? "/guides"
                : card.key === "learning_resources" && learningConfig(this.site)
                  ? "/isbf/learning"
                  : card.key === "library" && libraryConfig(this.site)
                    ? "/isbf/library"
                    : card.key === "careers" && careersConfig(this.site)
                      ? "/isbf/careers"
                      : card.key === "marketplace" &&
                          marketplaceConfig(this.site)
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
