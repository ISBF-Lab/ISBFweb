export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",

  map() {
    this.route("avatar-frames", { path: "frames" }, function () {
      this.route("new");
      this.route("edit", { path: "/:id/edit" });
      this.route("grants", { path: "/:id/grants" });
    });
  },
};
