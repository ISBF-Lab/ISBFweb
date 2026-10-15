import { find, findAll, render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import ResumePreview from "discourse/plugins/isbf-resume/discourse/components/resume-preview";

module("Integration | Component | ResumePreview", function (hooks) {
  setupRenderingTest(hooks, { stubRouter: true });

  test("an empty draft asks for content without displaying fictional resume information", async function (assert) {
    await render(<template><ResumePreview @unavailable={{true}} /></template>);

    assert
      .dom(".isbf-resume__preview")
      .includesText(
        i18n("isbf_resume.empty_draft_preview"),
        "explains how to see the user's own content"
      );
    assert
      .dom(".isbf-resume__paper")
      .doesNotExist("does not display the fictional template image");
    assert
      .dom(".isbf-resume__pages")
      .doesNotExist("does not present the sample as generated pages");
    assert
      .dom(".isbf-resume__downloads a")
      .doesNotExist("does not expose sample files as generated downloads");
    assert
      .dom(".isbf-resume__downloads button")
      .isDisabled("download actions start disabled");
  });

  test("draft content updates immediately and user markup remains plain text", async function (assert) {
    this.payload = {
      template: "blue-gold",
      basic: {
        name: "陈安",
        email: "chen@example.com",
        highest_education: "示例大学 · 软件工程 · 本科",
      },
      summary: { text: "参与过开源项目\n熟悉网页开发" },
      education: [{}],
    };
    await render(
      <template>
        <ResumePreview @payload={{this.payload}} @unavailable={{true}} />
      </template>
    );

    assert
      .dom(".isbf-resume-draft")
      .includesText("陈安", "renders the supplied name");
    assert
      .dom(".isbf-resume-draft")
      .includesText("chen@example.com", "renders the supplied contact detail");
    assert
      .dom(".isbf-resume-draft")
      .includesText(
        "示例大学 · 软件工程 · 本科",
        "includes the user's full education summary"
      );
    assert
      .dom('[data-section="summary"]')
      .includesText("熟悉网页开发", "includes multiline summary content");
    assert
      .dom('[data-section="education"]')
      .doesNotExist("omits empty experience modules");
    assert
      .dom(".isbf-resume__preview")
      .doesNotIncludeText(
        i18n("isbf_resume.sample"),
        "never identifies the user's content as a fictional sample"
      );

    this.set("payload", {
      ...this.payload,
      basic: {
        name: '<img src="x" onerror="alert(1)">',
        phone: "+86 13800000000",
      },
      summary: {},
    });
    await settled();

    assert
      .dom(".isbf-resume-draft")
      .includesText(
        '<img src="x" onerror="alert(1)">',
        "shows entered markup as escaped text"
      );
    assert
      .dom(".isbf-resume-draft img")
      .doesNotExist("does not execute entered markup");
    assert
      .dom(".isbf-resume-draft")
      .doesNotIncludeText(
        "chen@example.com",
        "removes a cleared field instead of retaining its previous value"
      );
    assert
      .dom('[data-section="summary"]')
      .doesNotExist("removes a cleared module without leaving a heading");
    assert
      .dom(".isbf-resume__downloads a")
      .doesNotExist("does not generate downloads while typing");
  });

  test("experience entries, dates and English headings preserve the supplied wording and order", async function (assert) {
    this.payload = {
      template: "blue-gray",
      language: "en",
      basic: {
        name: "Alex Chen",
        portfolio_links: "GitHub: https://github.com/example",
      },
      education: [
        {
          school: "Example University",
          major: "Computer science",
          degree: "BSc",
          start_month: "2023-09",
          end_month: "2027-06",
          ongoing: true,
          courses: "Algorithms",
          achievements: "Scholarship\n\nStudent research",
        },
      ],
      experience: [
        {
          company: "Example Studio",
          position: "Developer",
          department: "Web team",
          start_month: "2025-07",
          end_month: "2025-08",
          ongoing: true,
          details: "Built dashboards",
        },
        {
          company: "Earlier Studio",
          position: "Intern",
          details: "Reviewed UI",
        },
      ],
      projects: [
        {
          name: "Portfolio",
          role: "Designer",
          technology: "HTML / CSS",
          link: "https://example.com/portfolio",
          details: "Created mobile layouts",
        },
      ],
      activities: [
        {
          name: "Volunteer team",
          role: "Coordinator",
          details: "Organized sessions",
        },
      ],
      skills: [
        {
          name: "English",
          level: "C1",
          date: "2025-03",
          issuer: "Example Institute",
          description: "Professional communication",
        },
      ],
      honors: [
        {
          name: "Design award",
          date: "2025-04",
          issuer: "Example Society",
          description: "First place",
        },
      ],
      summary: { text: "中文原文保留" },
    };
    await render(
      <template>
        <ResumePreview @payload={{this.payload}} @unavailable={{true}} />
      </template>
    );

    assert
      .dom(".isbf-resume-draft")
      .hasAttribute("lang", "en", "identifies the output language");
    assert
      .dom(".isbf-resume-draft")
      .hasAttribute(
        "data-template",
        "blue-gray",
        "uses the selected color variant"
      );
    assert
      .dom(".isbf-resume-draft__heading")
      .hasText(
        "Personal information",
        "uses the same fixed English heading as the export"
      );
    assert
      .dom('[data-section="education"]')
      .includesText(
        "2023.09 - 2027.06 (expected)",
        "formats expected graduation consistently with the export"
      );
    assert
      .dom('[data-section="education"]')
      .includesText(
        "Computer science · BSc",
        "preserves both major and degree"
      );
    assert
      .dom('[data-section="education"] li')
      .exists({ count: 2 }, "retains nonempty achievement lines");
    assert
      .dom('[data-section="experience"] .isbf-resume-draft__entry')
      .exists({ count: 2 }, "retains both work entries");
    assert
      .dom(findAll('[data-section="experience"] .isbf-resume-draft__entry')[0])
      .includesText("Example Studio", "preserves the user's entry order");
    assert
      .dom('[data-section="experience"]')
      .includesText(
        "2025.07 - Present",
        "uses the current-employment date convention"
      );
    for (const [section, values] of Object.entries({
      projects: [
        "Portfolio",
        "HTML / CSS",
        "https://example.com/portfolio",
        "Created mobile layouts",
      ],
      activities: ["Coordinator", "Organized sessions"],
      skills: [
        "C1",
        "2025.03",
        "Example Institute",
        "Professional communication",
      ],
      honors: ["2025.04", "Example Society", "First place"],
      summary: ["中文原文保留"],
    })) {
      for (const value of values) {
        assert
          .dom(`[data-section="${section}"]`)
          .includesText(value, `preserves ${section} content: ${value}`);
      }
    }
    assert
      .dom(".isbf-resume-draft a")
      .doesNotExist(
        "treats supplied URLs as document text without external requests"
      );
  });

  test("the private photo appears from the current draft and disappears when removed", async function (assert) {
    const photo =
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6VSAAAAAASUVORK5CYII=";
    this.payload = { basic: { name: "陈安", photo } };
    await render(
      <template>
        <ResumePreview @payload={{this.payload}} @unavailable={{true}} />
      </template>
    );
    assert
      .dom(".isbf-resume-draft__photo")
      .hasAttribute("src", photo, "uses the locally selected photo directly");

    this.set("payload", { basic: { name: "陈安", photo: "" } });
    await settled();
    assert
      .dom(".isbf-resume-draft__photo")
      .doesNotExist("removes the photo without reserving an empty frame");
    this.set("payload", {
      basic: { photo: "https://example.com/private.png" },
    });
    await settled();
    assert
      .dom(".isbf-resume-draft img")
      .doesNotExist("does not request an arbitrary external photo URL");
  });

  test("generated PDF pages and document links are withdrawn when unavailable or stale", async function (assert) {
    const exportPath =
      "/isbf-resume/exports/11111111-1111-4111-8111-111111111111";
    this.result = {
      pages: 2,
      docx_url: `${exportPath}/docx`,
      pdf_url: `${exportPath}/pdf`,
      preview_urls: [`${exportPath}/previews/1`, `${exportPath}/previews/2`],
    };
    this.stale = false;
    this.unavailable = false;
    this.payload = { basic: { name: "已修改的姓名" } };

    await render(
      <template>
        <ResumePreview
          @payload={{this.payload}}
          @result={{this.result}}
          @stale={{this.stale}}
          @template="blue-gray"
          @unavailable={{this.unavailable}}
        />
      </template>
    );

    assert
      .dom(`a[href="${this.result.docx_url}"]`)
      .exists("offers the owner-bound DOCX result");
    assert
      .dom(`a[href="${this.result.pdf_url}"]`)
      .exists("offers the owner-bound PDF result");
    const primaryClick = new MouseEvent("click", { button: 0 });
    for (const format of ["docx", "pdf"]) {
      const link = find(`a[href="${this.result[`${format}_url`]}"]`);
      assert
        .dom(link)
        .hasAttribute(
          "download",
          "",
          `${format} uses native download semantics`
        );
      assert
        .dom(link)
        .hasAttribute(
          "target",
          "_blank",
          `${format} leaves the resume editor open`
        );
      assert
        .dom(link)
        .hasAttribute(
          "rel",
          "noopener noreferrer",
          `${format} follows the Core native download pattern`
        );
      assert.true(
        wantsNewWindow(primaryClick, link),
        `${format} satisfies Core navigation bypass for an unmodified primary click`
      );
    }
    assert
      .dom(`a[href="${this.result.pdf_url}?inline=1"]`)
      .hasAttribute(
        "target",
        "_blank",
        "opens the actual PDF with native navigation"
      );
    assert
      .dom(".isbf-resume__pages img")
      .exists({ count: 2 }, "shows all pages of the generated PDF");
    findAll(".isbf-resume__pages img").forEach((page, index) => {
      assert
        .dom(page)
        .hasAttribute(
          "src",
          this.result.preview_urls[index],
          `page ${index + 1} uses the protected PDF page URL`
        );
      assert
        .dom(page)
        .hasAttribute(
          "alt",
          i18n("isbf_resume.preview_page", { count: 2, page: index + 1 }),
          `page ${index + 1} identifies its position in the PDF`
        );
    });
    assert
      .dom("iframe")
      .doesNotExist(
        "previews the PDF without requiring an embedded browser viewer"
      );

    this.set("unavailable", true);
    await settled();

    assert
      .dom(".isbf-resume__preview img")
      .doesNotExist("withdraws every page URL when the export is unavailable");
    assert
      .dom(".isbf-resume__downloads a")
      .doesNotExist("withdraws document links when the export is unavailable");

    this.setProperties({ stale: true, unavailable: false });
    await settled();

    assert
      .dom(".isbf-resume__preview")
      .includesText(
        i18n("isbf_resume.stale"),
        "asks for regeneration after an edit"
      );
    assert
      .dom(".isbf-resume__downloads a")
      .doesNotExist("withdraws downloads and the separate PDF link");
    assert
      .dom(".isbf-resume__preview img")
      .doesNotExist("withdraws every page URL after a draft edit");
    assert
      .dom(".isbf-resume__pages")
      .doesNotExist("removes the old PDF paper layout");
    assert
      .dom(".isbf-resume-draft")
      .includesText(
        "已修改的姓名",
        "shows the current draft after withdrawing stale PDF pages"
      );
    assert
      .dom(".isbf-resume__downloads button")
      .exists(
        { count: 2 },
        "keeps both document actions available for feedback"
      );
    findAll(".isbf-resume__downloads button").forEach((button) => {
      assert
        .dom(button)
        .isDisabled("keeps download actions unavailable until regeneration");
    });
  });

  test("generation withdraws an older result and exposes a readable busy state", async function (assert) {
    const result = {
      pages: 1,
      docx_url: "/isbf-resume/exports/previous/docx",
      pdf_url: "/isbf-resume/exports/previous/pdf",
      preview_urls: ["/isbf-resume/exports/previous/previews/1"],
    };
    await render(
      <template>
        <ResumePreview
          @busy={{true}}
          @result={{result}}
          @stale={{false}}
          @template="blue-gold"
          @unavailable={{false}}
        />
      </template>
    );

    assert
      .dom(".isbf-resume__preview")
      .hasAttribute(
        "aria-busy",
        "true",
        "marks generation as busy for assistive technology"
      );
    assert
      .dom(".isbf-resume__preview")
      .includesText(
        i18n("isbf_resume.generating_preview"),
        "explains that the new preview is pending"
      );
    assert
      .dom(".isbf-resume__preview img")
      .doesNotExist(
        "hides the previous PDF and template examples during generation"
      );
    assert
      .dom(".isbf-resume__downloads a")
      .doesNotExist("withdraws every old document link while generating");
    findAll(".isbf-resume__downloads button").forEach((button) => {
      assert
        .dom(button)
        .isDisabled(
          "keeps both file actions disabled until generation completes"
        );
    });
  });

  test("an older export without page images still offers its document downloads", async function (assert) {
    this.result = {
      pages: 1,
      docx_url: "/isbf-resume/exports/example/docx",
      pdf_url: "/isbf-resume/exports/example/pdf",
      preview_urls: [],
    };

    await render(
      <template>
        <ResumePreview
          @result={{this.result}}
          @template="blue-gray"
          @unavailable={{false}}
        />
      </template>
    );

    assert
      .dom(".isbf-resume__preview")
      .includesText(
        i18n("isbf_resume.preview_unavailable"),
        "explains how to obtain actual page previews"
      );
    assert
      .dom(".isbf-resume__preview img")
      .doesNotExist(
        "does not substitute a fictional sample for a generated result"
      );
    assert
      .dom(".isbf-resume__pages")
      .doesNotExist("does not retain an empty paper layout");
    assert
      .dom('a[href="/isbf-resume/exports/example/docx"]')
      .exists("keeps the older DOCX accessible");
    assert
      .dom('a[href="/isbf-resume/exports/example/pdf"]')
      .exists("keeps the older PDF accessible");
  });
});
