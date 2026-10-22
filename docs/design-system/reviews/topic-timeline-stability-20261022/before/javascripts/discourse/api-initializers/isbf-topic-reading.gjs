import { apiInitializer } from "discourse/lib/api";
import ISBFTopicReading, {
  ISBFTopicReadingJump,
} from "../components/isbf-topic-reading";

export default apiInitializer((api) => {
  api.renderInOutlet("topic-navigation", ISBFTopicReading);
  api.renderInOutlet("timeline-footer-controls-after", ISBFTopicReadingJump);
});
