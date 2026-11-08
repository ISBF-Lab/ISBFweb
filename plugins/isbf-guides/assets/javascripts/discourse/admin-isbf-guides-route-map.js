export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",

  map() {
    this.route("isbf-guides-guides", { path: "guides" }, function () {
      this.route("new");
      this.route("edit", { path: "/:guide_id" });
    });
  },
};
