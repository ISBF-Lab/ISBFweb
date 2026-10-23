import { themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import { isOfficialComposer, officialConfig } from "../lib/official-filters";

export default apiInitializer((api) => {
  const composer = api.container.lookup("service:composer");
  const site = api.container.lookup("service:site");

  api.modifyClass("component:mini-tag-chooser", {
    pluginId: "isbf-ui-official-composer-tags",

    modifyNoSelection() {
      const original = this._super(...arguments);
      const config = officialConfig(site);
      const options = this.selectKit.options;
      if (
        !composer.isOpen ||
        !isOfficialComposer(composer.model, config) ||
        Number(options.categoryId) !== config.category_id ||
        !options.prioritizeRecentTags ||
        options.minimum > 0
      ) {
        return original;
      }
      return this.defaultItem(null, i18n(themePrefix("isbf_v2.official_tags")));
    },
  });
});
