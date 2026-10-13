export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",

  map() {
    this.route("academy-moderator-permissions", {
      path: "moderator-permissions",
    });
    this.route(
      "academy-student-invites",
      { path: "student-invites" },
      function () {
        this.route("new");
        this.route("bulk");
      }
    );
  },
};
