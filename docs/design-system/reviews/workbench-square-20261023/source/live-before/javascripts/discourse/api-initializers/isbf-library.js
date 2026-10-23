import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  api.registerReviewableComponent(
    "ReviewableIsbfLibraryDirectory",
    async () =>
      (await import("../components/reviewable-isbf-library-directory")).default,
  );
});
