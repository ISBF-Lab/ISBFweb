import { withPluginApi } from "discourse/lib/plugin-api";
import User from "discourse/models/user";

const STAFF_INFO_FIELDS = [
  "number_of_deleted_posts",
  "number_of_flags",
  "number_of_flags_given",
  "number_of_silencings",
  "number_of_suspensions",
  "warnings_received_count",
  "number_of_rejected_posts",
  "can_remove_password",
];

function clearStaffInfo(user) {
  user.setProperties(
    Object.fromEntries(STAFF_INFO_FIELDS.map((field) => [field, undefined]))
  );
}

export default {
  name: "academy-user-staff-info",
  before: "inject-discourse-objects",

  initialize() {
    withPluginApi((api) => {
      const originalFindStaffInfo = User.prototype.findStaffInfo;

      api.addModelMethod("user", "findStaffInfo", function (...args) {
        if (this.academy_can_see_staff_info === false) {
          clearStaffInfo(this);
          return Promise.resolve(null);
        }

        return originalFindStaffInfo.apply(this, args).catch((error) => {
          if (error.jqXHR?.status !== 403) {
            throw error;
          }

          this.set("academy_can_see_staff_info", false);
          clearStaffInfo(this);
          return null;
        });
      });
    });
  },
};
