import { withPluginApi } from "discourse/lib/plugin-api";
import AcademyPasswordSetupPrompt from "../components/academy-password-setup-prompt";

export default {
  name: "academy-password-setup",

  initialize() {
    withPluginApi((api) => {
      api.renderInOutlet("main-outlet-bottom", AcademyPasswordSetupPrompt);
    });
  },
};
