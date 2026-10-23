import { apiInitializer } from "discourse/lib/api";
import ISBFProfileSummary from "../components/isbf-profile-summary";

export default apiInitializer((api) => {
  api.renderInOutlet("below-user-summary-stats", ISBFProfileSummary);
});
