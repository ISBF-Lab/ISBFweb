export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",
  map() {
    this.route("isbf-account-switch-links", { path: "links" });
  },
};
