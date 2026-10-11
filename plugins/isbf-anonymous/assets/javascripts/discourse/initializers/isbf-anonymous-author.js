import { apiInitializer } from "discourse/lib/api";
import IsbfAnonymousAuthor from "../components/modal/isbf-anonymous-author";

export default apiInitializer((api) => {
  const currentUser = api.getCurrentUser();

  api.addPostAdminMenuButton((post) => {
    if (
      !(
        currentUser?.admin ||
        currentUser?.academy_moderator_permissions?.trace_anonymous
      ) ||
      !post.isbf_per_post_anonymous
    ) {
      return;
    }

    return {
      action: () => {
        api.container.lookup("service:modal").show(IsbfAnonymousAuthor, {
          model: { id: post.id, type: "posts" },
        });
      },
      className: "isbf-anonymous-author-lookup",
      icon: "user",
      label: "isbf_anonymous.author_lookup.button",
    };
  });
});
