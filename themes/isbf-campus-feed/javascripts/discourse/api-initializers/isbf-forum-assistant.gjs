import { apiInitializer } from "discourse/lib/api";
import ISBFV2Brand from "../components/isbf-v2-brand";

export default apiInitializer((api) => {
  api.renderInOutlet(
    "forum-assistant-brand",
    <template><ISBFV2Brand @compact={{false}} @mobile={{true}} /></template>
  );
});
