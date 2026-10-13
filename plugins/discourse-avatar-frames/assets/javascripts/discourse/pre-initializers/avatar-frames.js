import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "avatar-frames",
  before: "inject-discourse-objects",

  initialize() {
    withPluginApi((api) => {
      const userClass = api.container.factoryFor("model:user").class;
      const originalSave = userClass.prototype.save;

      api.addModelMethod("user", "save", async function (...args) {
        const result = await originalSave.apply(this, args);
        if (Object.hasOwn(result.user || {}, "avatar_frame")) {
          this.set("avatar_frame", result.user.avatar_frame);
          const currentUser = api.getCurrentUser();
          if (this.id === currentUser?.id) {
            currentUser.set("avatar_frame", result.user.avatar_frame);
          }
        }
        return result;
      });
    });
  },
};
