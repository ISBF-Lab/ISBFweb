import { apiInitializer } from "discourse/lib/api";
import ISBFContinueReading from "../components/isbf-continue-reading";

export default apiInitializer((api) => {
  api.renderInOutlet("more-topics-content", ISBFContinueReading);
});
