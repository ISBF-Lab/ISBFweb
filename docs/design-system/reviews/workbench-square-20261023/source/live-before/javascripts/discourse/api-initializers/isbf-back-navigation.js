import { getOwner } from "@ember/owner";
import { apiInitializer } from "discourse/lib/api";
import ISBFBackNavigation from "../services/isbf-back-navigation";

export default apiInitializer((api) => {
  const owner = getOwner(api.container.lookup("service:router"));
  if (!owner.hasRegistration("service:isbf-back-navigation")) {
    owner.register("service:isbf-back-navigation", ISBFBackNavigation);
  }
  owner.lookup("service:isbf-back-navigation");
});
