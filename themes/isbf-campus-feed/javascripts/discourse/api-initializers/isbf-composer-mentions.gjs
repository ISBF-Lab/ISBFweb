import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import UserAutocompleteResults from "discourse/components/user-autocomplete-results";
import { apiInitializer } from "discourse/lib/api";
import userSearch from "discourse/lib/user-search";
import {
  destroyUserStatuses,
  initUserStatusHtml,
} from "discourse/lib/user-status-on-autocomplete";
import { isQuickPost } from "../lib/quick-post-scope";

function canSuggestUsers(model, currentURL) {
  const path = currentURL?.split(/[?#]/, 1)[0];
  return (
    (path === "/" || path === "/latest") &&
    isQuickPost(model) &&
    (!model.categoryId || model.category?.read_restricted === false)
  );
}

export default apiInitializer((api) => {
  api.modifyClass("component:d-editor", (Superclass) => {
    return class extends Superclass {
      @action
      setupEditor(textManipulation) {
        const model = this.outletArgs?.composer;
        if (!model?.creatingTopic) {
          return super.setupEditor(textManipulation);
        }

        const owner = getOwner(this);
        const router = owner.lookup("service:router");
        const autocomplete =
          textManipulation.autocomplete.bind(textManipulation);
        const descriptor = Object.getOwnPropertyDescriptor(
          textManipulation,
          "autocomplete"
        );

        // The editor registers its native autocomplete handlers during setup.
        textManipulation.autocomplete = (options) => {
          if (options?.component !== UserAutocompleteResults) {
            return autocomplete(options);
          }

          return autocomplete({
            ...options,
            dataSource: (term) => {
              if (term !== "" || !canSuggestUsers(model, router.currentURL)) {
                return options.dataSource(term);
              }

              destroyUserStatuses();
              return userSearch({
                term,
                lastSeenUsers: true,
                exclude: [this.currentUser.username],
              }).then((results) => {
                initUserStatusHtml(owner, results.users);
                return results;
              });
            },
          });
        };

        try {
          return super.setupEditor(textManipulation);
        } finally {
          if (descriptor) {
            Object.defineProperty(textManipulation, "autocomplete", descriptor);
          } else {
            delete textManipulation.autocomplete;
          }
        }
      }
    };
  });
});
