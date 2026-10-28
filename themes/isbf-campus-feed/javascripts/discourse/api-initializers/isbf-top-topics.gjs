import { apiInitializer } from "discourse/lib/api";
import ISBFTopTopicsArea from "../components/isbf-top-topics-area";

export default apiInitializer((api) => {
  api.renderInOutlet("discovery-list-area", ISBFTopTopicsArea);
});
