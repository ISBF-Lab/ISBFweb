export default function () {
  this.route("isbfResume", { path: "/isbf/workbench/resume" });
  this.route("isbfResumeGenerate", { path: "/isbf/workbench/resume/generate" });
  this.route(
    "isbfResumeShares",
    { path: "/isbf/workbench/resume/shares" },
    function () {
      this.route("new");
      this.route("mine");
      this.route("review");
      this.route("show", { path: "/:id" });
    }
  );
}
