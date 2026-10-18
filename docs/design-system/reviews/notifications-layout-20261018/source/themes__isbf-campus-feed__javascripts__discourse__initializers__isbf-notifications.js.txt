import ISBFNotifications from "../services/isbf-notifications";

export function initialize(_container, owner) {
  owner.register("service:isbf-notifications", ISBFNotifications);
}

export default {
  name: "isbf-notification-state",
  after: "inject-objects",
  initialize,
};
