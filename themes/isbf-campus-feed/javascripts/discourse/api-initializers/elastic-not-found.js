import { scheduleOnce } from "@ember/runloop";
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  const a11y = api.container.lookup("service:a11y");
  let currentRoot;
  let destroy;
  let generation = 0;

  function synchronize() {
    const candidate = document.querySelector("[data-elastic-not-found]");
    // Custom pages can retain an error placeholder inside a hidden outlet.
    const root = candidate?.getClientRects().length ? candidate : null;
    if (!root) {
      document.body.classList.remove("elastic-not-found-page");
    }
    if (root === currentRoot) {
      return;
    }
    destroy?.();
    destroy = null;
    currentRoot = root;
    const requestedGeneration = ++generation;
    if (!root) {
      return;
    }

    import(root.dataset.interactionUrl)
      .then(({ mountNotFound }) => {
        if (requestedGeneration === generation && root.isConnected) {
          destroy = mountNotFound(root, {
            announce: (message) => a11y.announce(message, "polite"),
          });
        }
      })
      .catch((error) => {
        // The server-rendered message and home link remain usable offline.
        // eslint-disable-next-line no-console
        console.error("Unable to load the not-found interaction", error);
      });
  }

  api.onPageChange(() => scheduleOnce("afterRender", synchronize));
});
