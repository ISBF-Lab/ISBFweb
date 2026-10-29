import { scheduleOnce } from "@ember/runloop";
import { apiInitializer } from "discourse/lib/api";
import { isDevelopment } from "discourse/lib/environment";
import { errorPreview } from "../lib/error-preview";

export default apiInitializer((api) => {
  const preview = errorPreview(new URLSearchParams(window.location.search), {
    development: isDevelopment(),
  });
  if (!preview) {
    return;
  }

  const exception = api.container.lookup("service:exception");
  const router = api.container.lookup("service:router");
  const color = api.container.lookup("service:interface-color");
  let shown = false;
  let restoreColor;

  function showPreview() {
    if (preview.scheme) {
      const originalMode = color.colorModeIsDark
        ? "dark"
        : color.colorModeIsLight
          ? "light"
          : "auto";
      let restored = false;
      restoreColor = () => {
        if (restored) {
          return;
        }
        restored = true;
        window.removeEventListener("pagehide", restoreColor);
        if (originalMode === "dark") {
          color.forceDarkMode();
        } else if (originalMode === "light") {
          color.forceLightMode();
        } else {
          color.useAutoMode();
        }
      };
      window.addEventListener("pagehide", restoreColor, { once: true });
      preview.scheme === "dark"
        ? color.forceDarkMode()
        : color.forceLightMode();
    }

    exception.show(preview.error, {
      retry: () => window.location.reload(),
    });
  }

  api.onPageChange(() => {
    if (shown) {
      if (router.currentRouteName !== "exception") {
        restoreColor?.();
      }
      return;
    }
    shown = true;
    scheduleOnce("afterRender", showPreview);
  });
});
