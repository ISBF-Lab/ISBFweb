export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",

  map() {
    this.route("isbf-join-applications", { path: "applications" });
  },
};
