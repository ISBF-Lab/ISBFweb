import { apiInitializer } from "discourse/lib/api";
import ReviewableIsbfResume from "../components/reviewable-isbf-resume";

export default apiInitializer((api) => {
  api.registerReviewableComponent(
    "ReviewableIsbfResume",
    () => ReviewableIsbfResume
  );
});
