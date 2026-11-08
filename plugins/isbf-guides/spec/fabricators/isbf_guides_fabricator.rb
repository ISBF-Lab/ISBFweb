# frozen_string_literal: true

Fabricator(:isbf_guide, class_name: "IsbfGuides::Guide") do
  transient :editor
  slug { sequence(:guide_slug) { |number| "guide-#{number}" } }

  after_create do |guide, transient|
    revision =
      Fabricate(:isbf_guide_revision, guide:, editor: transient[:editor] || Fabricate(:admin))
    guide.update!(draft_revision: revision)
  end
end

Fabricator(:published_isbf_guide, from: :isbf_guide) do
  after_create do |guide|
    published = guide.draft_revision
    published.update!(published_at: Time.current)
    draft =
      Fabricate(
        :isbf_guide_revision,
        **published.content_attributes.symbolize_keys,
        guide:,
        editor: published.editor,
      )
    guide.update!(
      published_revision: published,
      draft_revision: draft,
      first_published_at: published.published_at,
    )
  end
end

Fabricator(:isbf_guide_revision, class_name: "IsbfGuides::Revision") do
  guide { Fabricate(:isbf_guide) }
  editor { Fabricate(:admin) }
  title { sequence(:guide_title) { |number| "Guide #{number}" } }
  summary "Set up forum notifications."
  raw "## Before starting\n\nSign in to your account.\n\n### Allow notifications\n\nEnable forum messages."
end

Fabricator(:isbf_guide_image, class_name: "IsbfGuides::Image") do
  guide { Fabricate(:isbf_guide) }
  creator { Fabricate(:admin) }
  filename { sequence(:guide_image_filename) { |number| "step-#{number}.png" } }
  data { File.binread(File.expand_path("../fixtures/step.png", __dir__)) }
end

Fabricator(:isbf_html_guide, from: :isbf_guide) do
  after_create do |guide|
    guide.draft_revision.update!(
      content_format: "html",
      raw:
        '<section id="setup"><h2>Account setup</h2><article class="isbf-guide__step" id="step-one"><h3>First step</h3><p>Follow the existing instructions.</p></article></section>',
    )
  end
end
