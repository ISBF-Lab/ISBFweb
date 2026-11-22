# frozen_string_literal: true

require_relative "../plugin_helper"

RSpec.describe IsbfWorkbenchMaintenance do
  it "keeps all existing entries available until their own maintenance switch is saved" do
    theme_settings = YAML.safe_load_file(Rails.root.join("themes/isbf-campus-feed/settings.yml"))
    default_entries = theme_settings.dig("workbench_entries", "default")
    expect(described_class::ENTRY_KEYS).to eq(default_entries.map { |entry| entry.fetch("key") })
    expect(described_class::ENTRY_KEYS.map { |key| described_class.paused?(key) }).to all(eq(false))

    SiteSetting.isbf_workbench_pause_learning_resources = true

    expect(described_class.paused?(:learning_resources)).to eq(true)
    expect(described_class.paused?(:library)).to eq(false)
    expect { described_class.ensure_available!(:learning_resources) }.to raise_error(
      Discourse::NotFound,
    )
    expect { described_class.ensure_available!(:library) }.not_to raise_error

    SiteSetting.isbf_workbench_pause_learning_resources = false

    expect { described_class.ensure_available!(:learning_resources) }.not_to raise_error
  end

  it "ignores unknown entry identifiers" do
    expect(described_class.paused?(nil)).to eq(false)
    expect(described_class.paused?("unknown")).to eq(false)
    expect(described_class.paused?("default_theme_id")).to eq(false)
  end
end
