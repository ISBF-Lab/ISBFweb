import { apiInitializer } from "discourse/lib/api";
import escape from "discourse/lib/escape";
import { WORKBENCH_ICONS } from "../lib/workbench-icons";

export default apiInitializer((api) => {
  api.registerIconRenderer({
    name: "isbf-workbench",

    string({ id }, options) {
      if (!Object.hasOwn(WORKBENCH_ICONS, id)) {
        return;
      }

      const classes = escape(
        `fa d-icon d-icon-${id} svg-icon svg-string ${options.class || ""}`
      );
      return `<svg aria-hidden="true" class="${classes}" fill="none" height="1em" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" viewBox="0 0 24 24" width="1em" xmlns="http://www.w3.org/2000/svg">${WORKBENCH_ICONS[id]}</svg>`;
    },
  });
});
