export default function () {
  this.route("isbfGuides", { path: "/guides" }, function () {
    this.route("show", { path: "/:slug" });
  });
}
