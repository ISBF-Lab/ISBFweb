import { apiInitializer } from "discourse/lib/api";
import ISBFBackNavigation from "../services/isbf-back-navigation";

export default apiInitializer((api) => {
  api.container.register("service:isbf-back-navigation", ISBFBackNavigation);
  api.container.lookup("service:isbf-back-navigation");
});
