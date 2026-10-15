import { registerReviewableTypeLabel } from "discourse/components/reviewable/item";
import { apiInitializer } from "discourse/lib/api";
import ReviewableIsbfResume from "../components/reviewable-isbf-resume";

export default apiInitializer((api) => {
  registerReviewableTypeLabel(
    "ReviewableIsbfResume",
    "review.types.reviewable_isbf_resume.title"
  );
  api.registerReviewableComponent(
    "ReviewableIsbfResume",
    () => ReviewableIsbfResume
  );
});
