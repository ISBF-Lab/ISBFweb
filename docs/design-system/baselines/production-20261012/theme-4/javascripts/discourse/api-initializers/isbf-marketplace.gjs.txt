import { themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import Composer from "discourse/models/composer";
import { i18n } from "discourse-i18n";
import { ISBFMarketplacePrice } from "../components/isbf-marketplace-card";
import ISBFMarketplaceComposer, {
  ISBFMarketplaceHome,
} from "../components/isbf-marketplace-composer";
import { extendComposerMethod } from "../lib/composer-model-extensions";
import {
  isMarketplaceComposer,
  MARKETPLACE_FIELDS,
  marketplacePayload,
  marketplaceUploadMarkdown,
  restoreMarketplace,
  validMarketplacePrice,
} from "../lib/marketplace";
import MarketplaceUpload from "../lib/marketplace-upload";

export default apiInitializer((api) => {
  const properties = [
    "isbfMarketplacePricePayload",
    "isbfMarketplaceImagesPayload",
    "isbfMarketplaceHomePayload",
  ];
  MARKETPLACE_FIELDS.forEach((field, index) => {
    Composer.serializeOnCreate(field, properties[index]);
    Composer.serializeOnUpdate(field, properties[index]);
    Composer.serializeToDraft(field, field);
    api.addModelGetter("composer", properties[index], function () {
      return marketplacePayload(this, field);
    });
  });
  extendComposerMethod(api, "clearState", function (next, ...args) {
    const result = next(...args);
    this.setProperties({
      isbf_marketplace_price: null,
      isbf_marketplace_images: null,
      isbf_marketplace_home: null,
    });
    return result;
  });
  extendComposerMethod(api, "open", function (next, options = {}) {
    return next(options).then((result) => {
      restoreMarketplace(this, options);
      return result;
    });
  });
  extendComposerMethod(api, "save", function (next, ...args) {
    if (
      isMarketplaceComposer(this) &&
      (!this.title?.trim() ||
        this.title.includes("[isbf-untitled:") ||
        !this.reply?.trim() ||
        !validMarketplacePrice(this.isbf_marketplace_price))
    ) {
      return Promise.resolve(
        this.dialog.alert(i18n(themePrefix("isbf_v2.marketplace_validation"))),
      );
    }
    return next(...args);
  });
  api.renderInOutlet("after-title-and-category", ISBFMarketplaceComposer);
  api.renderInOutlet("after-title-and-category", ISBFMarketplaceHome);
  api.customizeComposerText({
    titlePlaceholder: (model) =>
      isMarketplaceComposer(model)
        ? themePrefix("isbf_v2.marketplace_name")
        : null,
  });
  api.registerValueTransformer(
    "composer-editor-reply-placeholder",
    ({ value, context }) =>
      isMarketplaceComposer(context?.model?.model)
        ? themePrefix("isbf_v2.marketplace_description")
        : value,
  );
  api.renderAfterWrapperOutlet("post-metadata", ISBFMarketplacePrice);
  api.addComposerUploadPreProcessor(MarketplaceUpload, ({ composerModel }) => ({
    composerModel,
  }));
  api.addComposerUploadMarkdownResolver((upload) =>
    marketplaceUploadMarkdown(
      upload,
      api.container.lookup("service:composer").model,
    ),
  );
});
