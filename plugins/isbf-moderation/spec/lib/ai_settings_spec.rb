# frozen_string_literal: true

RSpec.describe IsbfModeration::AiSettingsValidator do
  fab!(:model) { Fabricate(:fake_model, vision_enabled: true) }

  before do
    SiteSetting.discourse_ai_enabled = true
    SiteSetting.isbf_ai_moderation_model = model.id.to_s
  end

  it "requires a model and its dependencies before enabling review" do
    SiteSetting.isbf_ai_moderation_model = ""
    expect { SiteSetting.isbf_ai_moderation_enabled = true }.to raise_error(
      Discourse::InvalidParameters,
    )
    SiteSetting.isbf_ai_moderation_model = model.id.to_s
    SiteSetting.discourse_ai_enabled = false
    expect { SiteSetting.isbf_ai_moderation_enabled = true }.to raise_error(
      Discourse::InvalidParameters,
    )
  end

  it "accepts stored false boolean values without requiring an AI connection" do
    SiteSetting.discourse_ai_enabled = false
    validator = described_class.new(name: :isbf_ai_moderation_enabled)
    expect(validator.valid_value?("f")).to eq(true)
    expect(validator.valid_value?("false")).to eq(true)
    expect(validator.valid_value?(false)).to eq(true)
  end

  it "requires image capability when enabling images or changing the active model" do
    text_model = Fabricate(:fake_model)
    SiteSetting.isbf_ai_moderation_enabled = true
    expect { SiteSetting.isbf_ai_moderation_model = text_model.id.to_s }.to raise_error(
      Discourse::InvalidParameters,
    )
    SiteSetting.isbf_ai_moderation_images_enabled = false
    SiteSetting.isbf_ai_moderation_model = text_model.id.to_s
    expect { SiteSetting.isbf_ai_moderation_images_enabled = true }.to raise_error(
      Discourse::InvalidParameters,
    )
  end

  it "offers existing model connections without exposing their secrets" do
    expect(IsbfModeration::AiModelEnumerator.values).to include(
      value: model.id.to_s,
      name: model.display_name,
    )
  end
end
