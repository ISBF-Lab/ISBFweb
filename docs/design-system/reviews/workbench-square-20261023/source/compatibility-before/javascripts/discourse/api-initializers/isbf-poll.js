import { themePrefix } from "virtual:theme";
import { apiInitializer } from "discourse/lib/api";
import { optionalRequire } from "discourse/lib/utilities";
import { i18n } from "discourse-i18n";

const initializedApis = new WeakSet();
const registeredToolbars = new WeakSet();

function pollBuilder() {
  try {
    return optionalRequire(
      "discourse/plugins/poll/discourse/components/modal/poll-ui-builder"
    );
  } catch {
    return null;
  }
}

export default apiInitializer((api) => {
  if (initializedApis.has(api)) {
    return;
  }
  initializedApis.add(api);

  const siteSettings = api.container.lookup("service:site-settings");
  const composer = api.container.lookup("service:composer");
  const modal = api.container.lookup("service:modal");
  let opening = false;
  const canCreatePoll = () => {
    const currentUser = api.getCurrentUser();
    return Boolean(
      composer.model &&
      !composer.model.isDestroyed &&
      !composer.model.isDestroying &&
      siteSettings.poll_enabled &&
      pollBuilder() &&
      (composer.model?.topic?.pm_with_non_human_user ||
        (currentUser && (currentUser.staff || currentUser.can_create_poll)))
    );
  };

  api.onToolbarCreate((toolbar) => {
    if (registeredToolbars.has(toolbar)) {
      return;
    }
    registeredToolbars.add(toolbar);
    toolbar.addButton({
      id: "isbf-poll",
      group: "extras",
      icon: "chart-bar",
      title: themePrefix("isbf_v2.poll_button_title"),
      translatedLabel: i18n(themePrefix("isbf_v2.poll_button")),
      condition: canCreatePoll,
      sendAction: async (toolbarEvent) => {
        const builder = pollBuilder();
        if (
          !builder ||
          !toolbarEvent ||
          !canCreatePoll() ||
          opening ||
          modal.activeModal?.component === builder
        ) {
          return;
        }
        opening = true;
        try {
          await modal.show(builder, { model: { toolbarEvent } });
        } finally {
          opening = false;
        }
      },
    });
  });
});
