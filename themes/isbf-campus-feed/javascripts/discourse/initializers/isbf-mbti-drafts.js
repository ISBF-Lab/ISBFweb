import { clearForeignMbtiDrafts } from "../lib/mbti";

export default {
  name: "isbf-mbti-drafts",
  after: "inject-objects",
  initialize(_container, owner) {
    const store = owner.lookup("service:key-value-store");
    const currentUser = owner.lookup("service:current-user");
    clearForeignMbtiDrafts(store, currentUser?.id);
  },
};
