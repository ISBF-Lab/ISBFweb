import { themePrefix } from "virtual:theme";
import { ajax } from "discourse/lib/ajax";
import Composer from "discourse/models/composer";
import { i18n } from "discourse-i18n";
import { extendComposerMethod } from "./composer-model-extensions";
import {
  isOfficialComposer,
  OFFICIAL_FIELDS,
  officialConfig,
  officialPayload,
  officialSelectionsAvailable,
  officialSelectionsComplete,
  restoreOfficialSelections,
} from "./official-filters";

const configuredComposers = new WeakSet();

export function setup(api) {
  if (configuredComposers.has(Composer)) {
    return;
  }
  const pendingSaves = new WeakMap();
  const epochs = new WeakMap();
  const invalidate = (model) => {
    epochs.set(model, (epochs.get(model) ?? 0) + 1);
    pendingSaves.delete(model);
    return epochs.get(model);
  };
  const refreshConfig = async (model, epoch) => {
    const data = await ajax("/site.json");
    if (epochs.get(model) !== epoch) {
      return null;
    }
    const config = officialConfig(data);
    if (!config) {
      throw new Error("Invalid official classification catalog");
    }
    model.site.set("isbf_official", data.isbf_official);
    return config;
  };

  OFFICIAL_FIELDS.forEach((field, index) => {
    const property =
      index === 0 ? "isbfOfficialCampusesPayload" : "isbfOfficialTypesPayload";
    api.addModelField("composer", field, { defaultValue: null });
    Composer.serializeOnCreate(field, property);
    Composer.serializeOnUpdate(field, property);
    Composer.serializeToDraft(field, field);
  });

  api.addModelGetter("composer", "isbfOfficialCampusesPayload", function () {
    return officialPayload(this, officialConfig(this.site), OFFICIAL_FIELDS[0]);
  });
  api.addModelGetter("composer", "isbfOfficialTypesPayload", function () {
    return officialPayload(this, officialConfig(this.site), OFFICIAL_FIELDS[1]);
  });

  extendComposerMethod(api, "clearState", function (next, ...args) {
    invalidate(this);
    const result = next(...args);
    this.setProperties({
      isbf_official_campuses: null,
      isbf_official_types: null,
    });
    return result;
  });
  extendComposerMethod(api, "open", function (next, ...args) {
    const epoch = invalidate(this);
    return next(...args).then((result) => {
      if (epochs.get(this) === epoch) {
        restoreOfficialSelections(this, officialConfig(this.site));
      }
      return result;
    });
  });
  extendComposerMethod(api, "save", function (next, ...args) {
    if (pendingSaves.has(this)) {
      return pendingSaves.get(this);
    }
    if (!isOfficialComposer(this, officialConfig(this.site))) {
      return next(...args);
    }
    const epoch = epochs.get(this);
    const pending = (async () => {
      let config;
      try {
        config = await refreshConfig(this, epoch);
      } catch {
        if (epochs.get(this) === epoch) {
          return this.dialog.alert(
            i18n(themePrefix("isbf_v2.official_refresh_error"))
          );
        }
        return;
      }
      if (epochs.get(this) !== epoch || !isOfficialComposer(this, config)) {
        return;
      }
      if (!officialSelectionsAvailable(this, config)) {
        return this.dialog.alert(
          i18n(themePrefix("isbf_v2.official_classification_stale"))
        );
      }
      if (!officialSelectionsComplete(this, config)) {
        return this.dialog.alert(
          i18n(themePrefix("isbf_v2.official_required"))
        );
      }
      try {
        return await next(...args);
      } catch (error) {
        if (epochs.get(this) === epoch) {
          try {
            await refreshConfig(this, epoch);
          } catch {
            // Keep the native save error even when the catalog refresh fails.
          }
        }
        throw error;
      }
    })().finally(() => {
      if (pendingSaves.get(this) === pending) {
        pendingSaves.delete(this);
      }
    });
    pendingSaves.set(this, pending);
    return pending;
  });
  configuredComposers.add(Composer);
}
