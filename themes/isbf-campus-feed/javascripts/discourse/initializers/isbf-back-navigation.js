import ISBFBackNavigation from "../services/isbf-back-navigation";

export function initialize(_container, owner) {
  owner.register("service:isbf-back-navigation", ISBFBackNavigation);
  owner.lookup("service:isbf-back-navigation");
}

export default {
  name: "isbf-back-navigation",
  after: "inject-objects",
  initialize,
};
