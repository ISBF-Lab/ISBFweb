export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",

  map() {
    this.route("isbf-moderation-modes", { path: "ai-moderation-modes" });
  },
};
