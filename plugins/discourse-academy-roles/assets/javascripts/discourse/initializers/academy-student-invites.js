import { withPluginApi } from "discourse/lib/plugin-api";
import AcademyStudentInvite from "../components/modal/academy-student-invite";

export default {
  name: "academy-student-invites",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    const siteSettings = container.lookup("service:site-settings");

    withPluginApi((api) => {
      api.registerValueTransformer(
        "invite-modal-component",
        ({ value, context }) => {
          if (
            siteSettings.academy_roles_enabled &&
            currentUser?.admin &&
            !context.opts.model?.editing
          ) {
            return AcademyStudentInvite;
          }
          return value;
        }
      );

      if (currentUser?.admin) {
        api.addAdminPluginConfigurationNav("discourse-academy-roles", [
          {
            label: "academy_roles.student_invites.title",
            route: "adminPlugins.show.academy-student-invites",
            description: "academy_roles.student_invites.description",
          },
        ]);
      }
    });
  },
};
