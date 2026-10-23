import { withPluginApi } from "discourse/lib/plugin-api";
import { setup } from "../lib/official-composer-setup";

export default {
  name: "isbf-official-composer",
  after: "isbf-composer-optional-title",
  before: "inject-discourse-objects",

  initialize() {
    withPluginApi((api) => setup(api));
  },
};
