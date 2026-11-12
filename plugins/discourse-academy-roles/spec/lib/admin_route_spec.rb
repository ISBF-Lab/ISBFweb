# frozen_string_literal: true

RSpec.describe DiscourseAcademyRoles do
  describe "admin route" do
    let(:plugin) { Discourse.plugins_by_name.fetch("discourse-academy-roles") }

    def client_text(locale, scope, *keys)
      JsLocaleHelper.load_translations(locale).dig(locale.to_s, scope, *keys)
    end

    %i[en zh_CN].each do |locale|
      it "names the plugin like its settings category in #{locale}" do
        label_keys = plugin.full_admin_route[:label].split(".")
        category =
          client_text(locale, "admin_js", "admin", "site_settings", "categories", "academy_roles")

        expect(category).to be_present
        expect(client_text(locale, "js", *label_keys)).to eq(category)
      end
    end

    it "keeps the student invitation tab label separate from the plugin name" do
      expect(plugin.full_admin_route[:label]).not_to eq("academy_roles.student_invites.title")
    end
  end
end
