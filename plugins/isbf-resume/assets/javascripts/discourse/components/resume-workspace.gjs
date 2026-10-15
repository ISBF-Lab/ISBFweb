import getURL from "discourse/lib/get-url";
import { eq } from "discourse/truth-helpers";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default <template>
  <section class="isbf-resume-workspace" ...attributes>
    <header class="isbf-resume-workspace__header">
      <a class="isbf-resume-workspace__back" href={{getURL "/isbf/workbench"}}>
        {{dIcon "arrow-left"}}
        <h1>{{i18n "isbf_resume.sharing.hub_title"}}</h1>
      </a>
    </header>
    <div class="isbf-resume-workspace__body">
      <nav
        aria-label={{i18n "isbf_resume.sharing.workspace_navigation"}}
        class="isbf-resume-workspace__navigation"
      >
        <a
          aria-current={{if (eq @section "shares") "page"}}
          href={{getURL "/isbf/workbench/resume/shares"}}
        >{{i18n "isbf_resume.sharing.share_navigation"}}</a>
        <a
          aria-current={{if (eq @section "generate") "page"}}
          href={{getURL "/isbf/workbench/resume/generate"}}
        >{{i18n "isbf_resume.sharing.generate_navigation"}}</a>
      </nav>
      <div class="isbf-resume-workspace__content">{{yield}}</div>
    </div>
  </section>
</template>
